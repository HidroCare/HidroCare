-- =====================================================================
-- HidroCare · 03 · Políticas de acesso (RLS)
-- Rodar DEPOIS do 02. Pode ser rodado de novo sem problema.
--
-- Este script APAGA todas as políticas atuais das 8 tabelas e cria o
-- conjunto abaixo do zero. É de propósito: políticas comuns se SOMAM
-- (com OU). Uma única política "using (true)" esquecida libera tudo e
-- anula as outras.
--
-- Matriz de acesso (L = ler, I = inserir, A = alterar, E = excluir)
--
--  tabela           professor      estudante
--  pacientes        L I A E        L (só os de cenários publicados)
--  cenarios         L I A E        L (só os publicados)
--  gabarito_itens   L I A E        nada (nunca lê o gabarito)
--  submissoes       L              L (só as suas)      -- escrita só pela função
--  registros        L              L (só os seus)      -- escrita só pela função
--  resultados       L              L (só os seus)      -- escrita só pela função
--  feedbacks        L I A E (seus) L (só os da sua submissão)
--  usuarios         L (todos)      L (só o seu) e A (só o nome)
--
-- "escrita só pela função" = enviar_atividade(), no script 04.
-- =====================================================================

alter table public.pacientes      enable row level security;
alter table public.cenarios       enable row level security;
alter table public.gabarito_itens enable row level security;
alter table public.submissoes     enable row level security;
alter table public.registros      enable row level security;
alter table public.resultados     enable row level security;
alter table public.feedbacks      enable row level security;
alter table public.usuarios       enable row level security;

-- Apagar TODAS as políticas atuais dessas tabelas -------------------------
do $$
declare r record;
begin
  for r in
    select policyname, tablename from pg_policies
    where schemaname = 'public'
      and tablename in ('pacientes', 'cenarios', 'gabarito_itens', 'submissoes',
                        'registros', 'resultados', 'feedbacks', 'usuarios')
  loop
    execute format('drop policy %I on public.%I', r.policyname, r.tablename);
  end loop;
end $$;

-- Quem não está logado não acessa nada ------------------------------------
revoke all on all tables in schema public from anon;

-- pacientes ---------------------------------------------------------------
create policy pacientes_professor on public.pacientes
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy pacientes_estudante_le on public.pacientes
  for select to authenticated
  using (exists (select 1 from public.cenarios c
                 where c.paciente_id = pacientes.id and c.publicado));

-- cenarios ----------------------------------------------------------------
create policy cenarios_professor on public.cenarios
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

create policy cenarios_estudante_le_publicados on public.cenarios
  for select to authenticated
  using (publicado);

-- gabarito_itens: SÓ o professor. O estudante nunca lê. -------------------
create policy gabarito_professor on public.gabarito_itens
  for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

-- submissoes: leitura apenas. Quem escreve é a função enviar_atividade(). -
create policy submissoes_le on public.submissoes
  for select to authenticated
  using (estudante_id = auth.uid() or public.is_admin());

-- registros ---------------------------------------------------------------
create policy registros_le on public.registros
  for select to authenticated
  using (public.is_admin()
         or exists (select 1 from public.submissoes s
                    where s.id = registros.submissao_id and s.estudante_id = auth.uid()));

-- resultados --------------------------------------------------------------
create policy resultados_le on public.resultados
  for select to authenticated
  using (public.is_admin()
         or exists (select 1 from public.submissoes s
                    where s.id = resultados.submissao_id and s.estudante_id = auth.uid()));

-- feedbacks ---------------------------------------------------------------
create policy feedbacks_le on public.feedbacks
  for select to authenticated
  using (public.is_admin()
         or exists (select 1 from public.submissoes s
                    where s.id = feedbacks.submissao_id and s.estudante_id = auth.uid()));

create policy feedbacks_professor_insere on public.feedbacks
  for insert to authenticated
  with check (public.is_admin() and professor_id = auth.uid());

create policy feedbacks_professor_altera on public.feedbacks
  for update to authenticated
  using (public.is_admin() and professor_id = auth.uid())
  with check (public.is_admin() and professor_id = auth.uid());

create policy feedbacks_professor_exclui on public.feedbacks
  for delete to authenticated
  using (public.is_admin() and professor_id = auth.uid());

-- usuarios ----------------------------------------------------------------
-- A criação da linha é feita pelas funções de cadastro (criar_perfil_hidrocare /
-- criar_usuario_hidrocare), que rodam com permissão própria. Não há política de insert.
create policy usuarios_le on public.usuarios
  for select to authenticated
  using (id = auth.uid() or public.is_admin());

create policy usuarios_altera_o_proprio on public.usuarios
  for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());

-- ---------------------------------------------------------------------
-- PERMISSÕES DAS TABELAS (grants)
-- O RLS decide QUAIS LINHAS cada um enxerga, mas antes disso o papel
-- "authenticated" precisa ter permissão básica na tabela. Sem isso aparece
-- o erro 42501 "permission denied for table ...". Concedemos só o necessário.
-- ---------------------------------------------------------------------
grant usage on schema public to authenticated;

-- leitura nas 8 tabelas (o RLS filtra as linhas)
grant select on public.pacientes, public.cenarios, public.gabarito_itens, public.usuarios,
                public.submissoes, public.registros, public.resultados, public.feedbacks
  to authenticated;

-- escrita só onde o professor mantém conteúdo (as políticas limitam ao professor)
grant insert, update, delete on public.pacientes, public.cenarios, public.gabarito_itens, public.feedbacks
  to authenticated;

-- submissões, registros e resultados: ninguém escreve direto; só a função enviar_atividade
revoke insert, update, delete on public.submissoes, public.registros, public.resultados from authenticated;

-- TRUNCATE, REFERENCES e TRIGGER não fazem parte do que o app precisa e o RLS
-- não controla o TRUNCATE. Tiramos para o usuário logado ficar só com o necessário.
revoke truncate, references, trigger on all tables in schema public from authenticated;

-- Mesmo na própria linha, o usuário só pode mudar o NOME (nunca o perfil).
revoke insert, update, delete on public.usuarios from authenticated;
grant  update (nome) on public.usuarios to authenticated;
