-- =====================================================================
-- HidroCare · 06 · Testes do banco (como estudante e como professor)
-- Rodar DEPOIS do 05.
--
-- IMPORTANTE: o SQL Editor roda como administrador do banco e IGNORA o RLS.
-- Por isso a função abaixo "vira" estudante e professor (troca o papel e
-- o e-mail da sessão) e testa como eles. Os dados criados no teste são
-- apagados ao final.
--
-- Como usar:
--   1) Rode este arquivo inteiro.
--   2) Rode:   select * from public.testar_banco_hidrocare();
--   3) Leia a coluna "resultado": tudo deve ser OK.
--   4) Rode:   drop function public.testar_banco_hidrocare();
-- =====================================================================

create or replace function public.testar_banco_hidrocare()
returns table (n integer, teste text, resultado text, detalhe text)
language plpgsql
as $$
declare
  c1        constant uuid := '00000000-0000-4000-8000-0000000000c1';
  c2        constant uuid := '00000000-0000-4000-8000-0000000000c2';
  v_est     uuid;  v_est_email text;
  v_prof    uuid;  v_prof_email text;
  v_cont    bigint;
  v_rows    bigint;
  v_json    jsonb;
  v_msg     text;
  v_estado  text;
  v_n       integer := 0;
  v_ok      boolean;
  v_det     text;
  v_nome    text;
begin
  select id, email into v_prof, v_prof_email from usuarios
    where email ~* '^pub[^@]*@mg\.senac\.br$' order by created_at limit 1;
  select id, email into v_est, v_est_email from usuarios
    where email !~* '^pub[^@]*@mg\.senac\.br$' order by created_at limit 1;
  if v_prof is null then raise exception 'Falta a conta do professor de teste.'; end if;
  if v_est  is null then raise exception 'Falta a conta de um estudante de teste.'; end if;
  if not exists (select 1 from cenarios where id = c1) then
    raise exception 'Rode antes o 05_dados_de_teste.sql.';
  end if;

  -- Limpa envios antigos de teste do estudante no cenário 01
  delete from resultados  where submissao_id in (select id from submissoes where estudante_id = v_est and cenario_id = c1);
  delete from registros   where submissao_id in (select id from submissoes where estudante_id = v_est and cenario_id = c1);
  delete from submissoes  where estudante_id = v_est and cenario_id = c1;

  -- ===== COMO ESTUDANTE =====
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_est, 'email', v_est_email, 'role', 'authenticated')::text, true);

  -- 1
  v_n := v_n + 1; select count(*) into v_cont from gabarito_itens;
  reset role; n := v_n; teste := 'Estudante NÃO lê o gabarito'; resultado := case when v_cont = 0 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas visíveis (esperado 0)'; return next;
  execute 'set local role authenticated';

  -- 2
  v_n := v_n + 1; select count(*) into v_cont from cenarios where id = c2;
  reset role; n := v_n; teste := 'Estudante NÃO vê cenário não publicado'; resultado := case when v_cont = 0 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas (esperado 0)'; return next;
  execute 'set local role authenticated';

  -- 3
  v_n := v_n + 1; select count(*) into v_cont from cenarios where id = c1;
  reset role; n := v_n; teste := 'Estudante vê o cenário publicado'; resultado := case when v_cont = 1 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas (esperado 1)'; return next;
  execute 'set local role authenticated';

  -- 4
  v_n := v_n + 1; select count(*) into v_cont from usuarios;
  reset role; n := v_n; teste := 'Estudante vê só o próprio cadastro'; resultado := case when v_cont = 1 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas (esperado 1)'; return next;
  execute 'set local role authenticated';

  -- 5
  v_n := v_n + 1; v_estado := null;
  begin update usuarios set perfil = 'professor' where id = v_est;
  exception when others then v_estado := sqlstate; end;
  reset role; n := v_n; teste := 'Estudante NÃO altera o próprio perfil'; resultado := case when v_estado = '42501' then 'OK' else 'FALHOU' end; detalhe := 'código do erro: ' || coalesce(v_estado, 'nenhum (alterou!)') || ' (esperado 42501)'; return next;
  execute 'set local role authenticated';

  -- 6
  v_n := v_n + 1; v_estado := null;
  begin insert into registros (submissao_id, tipo, valor_ml) values (gen_random_uuid(), 'entrada', 100);
  exception when others then v_estado := sqlstate; end;
  reset role; n := v_n; teste := 'Estudante NÃO insere registros direto'; resultado := case when v_estado = '42501' then 'OK' else 'FALHOU' end; detalhe := 'código do erro: ' || coalesce(v_estado, 'nenhum (inseriu!)') || ' (esperado 42501)'; return next;
  execute 'set local role authenticated';

  -- 7 envio vazio
  v_n := v_n + 1; v_msg := null;
  begin perform enviar_atividade(c1, '[]'::jsonb); exception when others then v_msg := sqlerrm; end;
  reset role; n := v_n; teste := 'Envio vazio é recusado'; resultado := case when v_msg is not null then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, 'aceitou!'); return next;
  execute 'set local role authenticated';

  -- 8 valor negativo
  v_n := v_n + 1; v_msg := null;
  begin perform enviar_atividade(c1, '[{"tipo":"entrada","valor_ml":-5}]'::jsonb); exception when others then v_msg := sqlerrm; end;
  reset role; n := v_n; teste := 'Valor negativo é recusado'; resultado := case when v_msg is not null then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, 'aceitou!'); return next;
  execute 'set local role authenticated';

  -- 9 cenário não publicado
  v_n := v_n + 1; v_msg := null;
  begin perform enviar_atividade(c2, '[{"tipo":"entrada","valor_ml":100}]'::jsonb); exception when others then v_msg := sqlerrm; end;
  reset role; n := v_n; teste := 'Envio em cenário não publicado é recusado'; resultado := case when v_msg is not null then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, 'aceitou!'); return next;
  execute 'set local role authenticated';

  -- 10 envio correto
  v_n := v_n + 1; v_msg := null; v_json := null;
  begin
    v_json := enviar_atividade(c1, '[
      {"tipo":"entrada","descricao":"Soro","valor_ml":500,"horario":"08:00"},
      {"tipo":"entrada","descricao":"Água","valor_ml":300,"horario":"10:00"},
      {"tipo":"saida","descricao":"Diurese","valor_ml":450,"horario":"12:00"}]'::jsonb);
  exception when others then v_msg := sqlerrm; end;
  reset role; n := v_n; teste := 'Envio correto: balanço +350, positivo, 3 acertos, 0 erros';
  v_ok := v_json is not null and (v_json->>'balanco_ml')::numeric = 350 and v_json->>'classificacao' = 'positivo'
          and (v_json->>'acertos')::int = 3 and (v_json->>'erros')::int = 0;
  resultado := case when v_ok then 'OK' else 'FALHOU' end; detalhe := coalesce(v_json::text, v_msg); return next;
  execute 'set local role authenticated';

  -- 11 segundo envio
  v_n := v_n + 1; v_msg := null;
  begin perform enviar_atividade(c1, '[{"tipo":"entrada","valor_ml":100}]'::jsonb); exception when others then v_msg := sqlerrm; end;
  reset role; n := v_n; teste := 'Segundo envio é recusado (RN05)'; resultado := case when v_msg is not null then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, 'aceitou!'); return next;
  execute 'set local role authenticated';

  -- 12 alterar submissão
  v_n := v_n + 1;
  v_rows := 0; v_msg := null;
  begin
    update submissoes set bloqueada = false where estudante_id = v_est;
    get diagnostics v_rows = row_count;
  exception when insufficient_privilege then v_msg := 'permissão negada (42501)'; end;
  reset role; n := v_n; teste := 'Estudante NÃO altera a submissão enviada'; resultado := case when v_rows = 0 then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, v_rows || ' linhas alteradas (esperado 0)'); return next;
  execute 'set local role authenticated';

  -- 13 apagar submissão
  v_n := v_n + 1;
  v_rows := 0; v_msg := null;
  begin
    delete from submissoes where estudante_id = v_est;
    get diagnostics v_rows = row_count;
  exception when insufficient_privilege then v_msg := 'permissão negada (42501)'; end;
  reset role; n := v_n; teste := 'Estudante NÃO apaga a submissão enviada'; resultado := case when v_rows = 0 then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, v_rows || ' linhas apagadas (esperado 0)'); return next;
  execute 'set local role authenticated';

  -- 14 lê o próprio resultado
  v_n := v_n + 1; select count(*) into v_cont from resultados;
  reset role; n := v_n; teste := 'Estudante lê o próprio resultado'; resultado := case when v_cont = 1 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas (esperado 1)'; return next;

  -- ===== COMO PROFESSOR =====
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_prof, 'email', v_prof_email, 'role', 'authenticated')::text, true);

  -- 15
  v_n := v_n + 1; select count(*) into v_cont from gabarito_itens where cenario_id = c1;
  reset role; n := v_n; teste := 'Professor lê o gabarito'; resultado := case when v_cont = 3 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas (esperado 3)'; return next;
  execute 'set local role authenticated';

  -- 16
  v_n := v_n + 1; select count(*) into v_cont from submissoes where estudante_id = v_est;
  reset role; n := v_n; teste := 'Professor lê as submissões da turma'; resultado := case when v_cont = 1 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas (esperado 1)'; return next;
  execute 'set local role authenticated';

  -- 17
  v_n := v_n + 1; v_msg := null;
  begin perform enviar_atividade(c1, '[{"tipo":"entrada","valor_ml":100}]'::jsonb); exception when others then v_msg := sqlerrm; end;
  reset role; n := v_n; teste := 'Professor NÃO envia atividade'; resultado := case when v_msg is not null then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, 'aceitou!'); return next;
  execute 'set local role authenticated';

  -- 18 feedback
  v_n := v_n + 1; v_msg := null;
  begin
    insert into feedbacks (submissao_id, professor_id, comentario)
    select id, v_prof, 'Bom trabalho (teste).' from submissoes where estudante_id = v_est limit 1;
  exception when others then v_msg := sqlerrm; end;
  reset role; n := v_n; teste := 'Professor registra feedback'; resultado := case when v_msg is null then 'OK' else 'FALHOU' end; detalhe := coalesce(v_msg, 'gravado'); return next;

  -- ===== COMO ESTUDANTE: feedback =====
  execute 'set local role authenticated';
  perform set_config('request.jwt.claims',
    json_build_object('sub', v_est, 'email', v_est_email, 'role', 'authenticated')::text, true);
  v_n := v_n + 1; select count(*) into v_cont from feedbacks;
  reset role; n := v_n; teste := 'Estudante lê o feedback da própria submissão'; resultado := case when v_cont = 1 then 'OK' else 'FALHOU' end; detalhe := v_cont || ' linhas (esperado 1)'; return next;

  -- ===== SEM LOGIN =====
  execute 'set local role anon';
  v_n := v_n + 1; v_estado := null;
  begin perform count(*) from cenarios; exception when others then v_estado := sqlstate; end;
  reset role; n := v_n; teste := 'Visitante sem login NÃO acessa tabelas'; resultado := case when v_estado = '42501' then 'OK' else 'FALHOU' end; detalhe := 'código do erro: ' || coalesce(v_estado, 'nenhum') || ' (esperado 42501)'; return next;

  -- Limpeza dos dados criados no teste
  delete from feedbacks  where submissao_id in (select id from submissoes where estudante_id = v_est and cenario_id = c1);
  delete from resultados where submissao_id in (select id from submissoes where estudante_id = v_est and cenario_id = c1);
  delete from registros  where submissao_id in (select id from submissoes where estudante_id = v_est and cenario_id = c1);
  delete from submissoes where estudante_id = v_est and cenario_id = c1;
end;
$$;

revoke all on function public.testar_banco_hidrocare() from public, anon, authenticated;

-- Depois de rodar este arquivo, rode:
--   select * from public.testar_banco_hidrocare();
-- E, para terminar:
--   drop function public.testar_banco_hidrocare();
