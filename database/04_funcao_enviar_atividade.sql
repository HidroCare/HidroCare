-- =====================================================================
-- HidroCare · 04 · Função enviar_atividade()
-- Rodar DEPOIS do 03. Pode ser rodado de novo sem problema.
--
-- É O CAMINHO ÚNICO pelo qual o estudante grava a atividade. Em uma
-- transação só, ela: valida os registros, recusa segundo envio, grava a
-- submissão (já bloqueada, RN05), calcula o balanço, corrige pelo
-- gabarito e grava o resultado.
--
-- Chamada na tela:
--   const { data, error } = await supabase.rpc('enviar_atividade', {
--     p_cenario: cenarioId,
--     p_registros: [
--       { tipo: 'entrada', descricao: 'Soro fisiológico', valor_ml: 500, horario: '08:00' },
--       { tipo: 'saida',   descricao: 'Diurese',          valor_ml: 450, horario: '12:00' }
--     ]
--   })
--   // erro de regra: error.message traz a frase em português
--   // sucesso: data = { submissao_id, balanco_ml, classificacao, acertos, erros }
--
-- security definer: a função roda com a permissão do dono, por isso consegue
-- ler o gabarito e gravar, mesmo o estudante não tendo acesso direto às tabelas.
-- O usuário vem de auth.uid() (a sessão), e NÃO de um parâmetro: o estudante
-- não consegue enviar em nome de outro.
--
-- CRITÉRIO DE CORREÇÃO (simplificado, depende do T02):
--   * um registro está correto se existe um item do gabarito do mesmo tipo
--     e com o mesmo valor, pareando os itens de cada tipo em ordem crescente
--     de valor (um item do gabarito corresponde a um só registro);
--   * v_margem é a tolerância em mL (0 = valor exato). Ajustar após o T02;
--   * erros = itens a mais do que acertos, entre registros enviados e
--     itens do gabarito (cobre registro errado e item que faltou).
-- =====================================================================

create or replace function public.enviar_atividade(p_cenario uuid, p_registros jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_margem  numeric := 0;            -- TODO (T02): tolerância de correção, em mL
  v_usuario uuid := auth.uid();
  v_sub     uuid;
  v_item    jsonb;
  v_pos     integer := 0;
  v_valor   numeric;
  v_balanco numeric;
  v_class   text;
  v_acertos integer;
  v_total   integer;
  v_gab     integer;
  v_erros   integer;
begin
  -- 1. Quem pode e o que pode ------------------------------------------
  if v_usuario is null then
    raise exception 'Faça login para enviar a atividade.';
  end if;
  if is_admin() then
    raise exception 'Apenas estudantes enviam atividades.';
  end if;
  if not exists (select 1 from cenarios where id = p_cenario and publicado) then
    raise exception 'Cenário não encontrado ou não publicado.';
  end if;
  if exists (select 1 from submissoes where cenario_id = p_cenario and estudante_id = v_usuario) then
    raise exception 'Você já enviou esta atividade.';
  end if;

  -- 2. Validar os registros (TODO T02: confirmar se envio vazio é permitido) --
  if p_registros is null or jsonb_typeof(p_registros) <> 'array' or jsonb_array_length(p_registros) = 0 then
    raise exception 'Informe ao menos um registro de entrada ou saída.';
  end if;

  for v_item in select * from jsonb_array_elements(p_registros) loop
    v_pos := v_pos + 1;

    if lower(coalesce(v_item->>'tipo', '')) not in ('entrada', 'saida', 'saída') then
      raise exception 'Registro %: tipo inválido (use entrada ou saida).', v_pos;
    end if;

    begin
      v_valor := (v_item->>'valor_ml')::numeric;
    exception when others then
      v_valor := null;
    end;
    if v_valor is null or v_valor = 'NaN'::numeric or v_valor <= 0 or v_valor > 100000 then
      raise exception 'Registro %: informe um valor numérico positivo em mL.', v_pos;
    end if;

    begin
      perform nullif(v_item->>'horario', '')::time;
    exception when others then
      raise exception 'Registro %: horário inválido (use HH:MM).', v_pos;
    end;
  end loop;

  -- 3. Gravar a submissão, já bloqueada (RN05) -------------------------
  v_sub := gen_random_uuid();
  insert into submissoes (id, cenario_id, estudante_id, enviada_em, bloqueada)
  values (v_sub, p_cenario, v_usuario, now(), true);

  -- 4. Gravar os registros e corrigir cada um pelo gabarito ------------
  insert into registros (id, submissao_id, tipo, descricao, horario, valor_ml, correto)
  with reg as (
    select
      case lower(t.x->>'tipo') when 'entrada' then 'entrada' else 'saida' end as tipo,
      nullif(trim(t.x->>'descricao'), '')                                     as descricao,
      nullif(t.x->>'horario', '')::time                                       as horario,
      (t.x->>'valor_ml')::numeric                                             as valor_ml,
      row_number() over (
        partition by case lower(t.x->>'tipo') when 'entrada' then 'entrada' else 'saida' end
        order by (t.x->>'valor_ml')::numeric, t.ord)                          as rn
    from jsonb_array_elements(p_registros) with ordinality as t(x, ord)
  ), gab as (
    select tipo, valor_ml, row_number() over (partition by tipo order by valor_ml, id) as rn
    from gabarito_itens
    where cenario_id = p_cenario
  )
  select gen_random_uuid(), v_sub, reg.tipo, reg.descricao, reg.horario, reg.valor_ml,
         coalesce(abs(reg.valor_ml - gab.valor_ml) <= v_margem, false)
  from reg
  left join gab on gab.tipo = reg.tipo and gab.rn = reg.rn;

  -- 5. Balanço, classificação e resultado ------------------------------
  select coalesce(sum(case tipo when 'entrada' then valor_ml else -valor_ml end), 0),
         count(*) filter (where correto),
         count(*)
    into v_balanco, v_acertos, v_total
    from registros
   where submissao_id = v_sub;

  select count(*) into v_gab from gabarito_itens where cenario_id = p_cenario;

  v_erros := greatest(v_total, v_gab) - v_acertos;
  v_class := case when v_balanco > 0 then 'positivo'
                  when v_balanco < 0 then 'negativo'
                  else 'neutro' end;

  insert into resultados (id, submissao_id, balanco_ml, classificacao, acertos, erros)
  values (gen_random_uuid(), v_sub, v_balanco, v_class, v_acertos, v_erros);

  return jsonb_build_object(
    'submissao_id',  v_sub,
    'balanco_ml',    v_balanco,
    'classificacao', v_class,
    'acertos',       v_acertos,
    'erros',         v_erros
  );
end;
$$;

-- Só quem está logado executa (a função também confere internamente).
revoke all on function public.enviar_atividade(uuid, jsonb) from public, anon;
grant execute on function public.enviar_atividade(uuid, jsonb) to authenticated;
