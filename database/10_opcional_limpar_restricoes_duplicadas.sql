-- =====================================================================
-- 10 (OPCIONAL, APÓS A APRESENTAÇÃO) · Limpar restrições duplicadas
-- =====================================================================
-- Só organização. Cada "repetida" é removida SOMENTE se a restrição
-- equivalente (a que fica) existir; se não existir, nada é apagado.
-- Seguro para rodar mais de uma vez.
-- =====================================================================
do $$
declare
  r record;
begin
  for r in
    select * from (values
      ('usuarios',       'usuarios_ra_key',                  'usuarios_ra_unique'),
      ('submissoes',     'uq_submissao_cenario_estudante',   'submissoes_unica_por_estudante'),
      ('resultados',     'resultados_submissao_id_key',      'resultados_uma_por_submissao'),
      ('gabarito_itens', 'gabarito_tipo_valido',             'gabarito_itens_tipo_check'),
      ('gabarito_itens', 'gabarito_valor_positivo',          'gabarito_itens_valor_ml_check'),
      ('registros',      'registros_tipo_valido',            'registros_tipo_check'),
      ('registros',      'registros_valor_positivo',         'registros_valor_ml_check'),
      ('resultados',     'resultados_classificacao_valida',  'resultados_classificacao_check')
    ) as t(tabela, repetida, fica)
  loop
    if exists (select 1 from pg_constraint where conrelid = ('public.'||r.tabela)::regclass and conname = r.fica)
       and exists (select 1 from pg_constraint where conrelid = ('public.'||r.tabela)::regclass and conname = r.repetida) then
      execute format('alter table public.%I drop constraint %I', r.tabela, r.repetida);
      raise notice 'removida % (fica %)', r.repetida, r.fica;
    else
      raise notice 'mantida % (equivalente % não encontrada ou já removida)', r.repetida, r.fica;
    end if;
  end loop;
end $$;

-- Estava só "não validada": valida as linhas existentes.
alter table public.cenarios validate constraint cenarios_periodo_positivo;
