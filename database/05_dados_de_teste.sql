-- =====================================================================
-- HidroCare · 05 · Dados de teste (paciente, cenário e gabarito)
-- Rodar DEPOIS do 04. Pode ser rodado de novo sem problema.
--
-- ANTES: criar as contas de demonstração (veja a rotina, passo 8):
--   * 1 professor  (e-mail pubXXXX@mg.senac.br)
--   * 1 estudante  (e-mail RA@senacminas.edu.br)
--
-- Gabarito do cenário 01: entradas 500 + 300 mL, saída 450 mL
-- => balanço esperado +350 mL (positivo).
-- =====================================================================

do $$
begin
  if not exists (select 1 from public.usuarios where email ~* '^pub[^@]*@mg\.senac\.br$') then
    raise exception 'Crie antes a conta do professor (e-mail pubXXXX@mg.senac.br) em Authentication > Users.';
  end if;
end $$;

insert into public.pacientes (id, nome, idade, sexo, massa, motivo_internacao) values
  ('00000000-0000-4000-8000-0000000000a1', 'Paciente Teste 01', 62, 'masculino', 78.5, 'Pós-operatório de colecistectomia')
on conflict (id) do nothing;

-- Cenário 01: publicado. Cenário 02: rascunho (o estudante não pode ver).
insert into public.cenarios (id, paciente_id, professor_id, titulo, enunciado, publicado, periodo_horas)
select '00000000-0000-4000-8000-0000000000c1', '00000000-0000-4000-8000-0000000000a1', u.id,
       'Cenário 01 — Pós-operatório (6 horas)',
       'Paciente em pós-operatório. Registre todas as entradas e saídas de líquidos observadas no período.',
       true, 6
from (select id from public.usuarios
      where email ~* '^pub[^@]*@mg\.senac\.br$' order by created_at limit 1) u
on conflict (id) do nothing;

insert into public.cenarios (id, paciente_id, professor_id, titulo, enunciado, publicado, periodo_horas)
select '00000000-0000-4000-8000-0000000000c2', '00000000-0000-4000-8000-0000000000a1', u.id,
       'Cenário 02 — Rascunho', 'Cenário ainda não publicado.', false, 24
from (select id from public.usuarios
      where email ~* '^pub[^@]*@mg\.senac\.br$' order by created_at limit 1) u
on conflict (id) do nothing;

insert into public.gabarito_itens (id, cenario_id, tipo, descricao, valor_ml, horario) values
  ('00000000-0000-4000-8000-0000000000b1', '00000000-0000-4000-8000-0000000000c1', 'entrada', 'Soro fisiológico',   500, '08:00'),
  ('00000000-0000-4000-8000-0000000000b2', '00000000-0000-4000-8000-0000000000c1', 'entrada', 'Água por via oral',  300, '10:00'),
  ('00000000-0000-4000-8000-0000000000b3', '00000000-0000-4000-8000-0000000000c1', 'saida',   'Diurese',           450, '12:00')
on conflict (id) do nothing;
