-- =====================================================================
-- 09 (OPCIONAL) · Só o professor DONO altera ou exclui o próprio cenário
-- =====================================================================
-- Hoje a regra usa is_admin(): qualquer professor altera o cenário de outro.
-- Depois deste script:
--   * todo professor continua LENDO todos os cenários e gabaritos;
--   * criar exige professor_id = o próprio usuário;
--   * alterar e excluir cenário, e mexer no gabarito, só no cenário que é seu.
-- Seguro para rodar mais de uma vez. Para voltar atrás, rode o script 03 de novo.
-- =====================================================================

-- CENÁRIOS ------------------------------------------------------------
drop policy if exists cenarios_professor           on public.cenarios;
drop policy if exists cenarios_professor_le        on public.cenarios;
drop policy if exists cenarios_professor_insere    on public.cenarios;
drop policy if exists cenarios_professor_altera    on public.cenarios;
drop policy if exists cenarios_professor_exclui    on public.cenarios;

create policy cenarios_professor_le on public.cenarios
  for select to authenticated using (is_admin());

create policy cenarios_professor_insere on public.cenarios
  for insert to authenticated
  with check (is_admin() and professor_id = auth.uid());

create policy cenarios_professor_altera on public.cenarios
  for update to authenticated
  using      (is_admin() and professor_id = auth.uid())
  with check (is_admin() and professor_id = auth.uid());

create policy cenarios_professor_exclui on public.cenarios
  for delete to authenticated
  using (is_admin() and professor_id = auth.uid());

-- GABARITO ------------------------------------------------------------
drop policy if exists gabarito_professor          on public.gabarito_itens;
drop policy if exists gabarito_professor_le       on public.gabarito_itens;
drop policy if exists gabarito_professor_insere   on public.gabarito_itens;
drop policy if exists gabarito_professor_altera   on public.gabarito_itens;
drop policy if exists gabarito_professor_exclui   on public.gabarito_itens;

create policy gabarito_professor_le on public.gabarito_itens
  for select to authenticated using (is_admin());

create policy gabarito_professor_insere on public.gabarito_itens
  for insert to authenticated
  with check (is_admin() and exists (
    select 1 from public.cenarios c where c.id = cenario_id and c.professor_id = auth.uid()));

create policy gabarito_professor_altera on public.gabarito_itens
  for update to authenticated
  using (is_admin() and exists (
    select 1 from public.cenarios c where c.id = cenario_id and c.professor_id = auth.uid()))
  with check (is_admin() and exists (
    select 1 from public.cenarios c where c.id = cenario_id and c.professor_id = auth.uid()));

create policy gabarito_professor_exclui on public.gabarito_itens
  for delete to authenticated
  using (is_admin() and exists (
    select 1 from public.cenarios c where c.id = cenario_id and c.professor_id = auth.uid()));
