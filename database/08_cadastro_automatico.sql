-- =====================================================================
-- HidroCare · 08 · Cadastro automático do perfil (usuarios)
-- Rodar DEPOIS do 03. Pode ser rodado de novo sem problema.
--
-- Corrige 4 coisas encontradas na conferência do banco:
--  1) a função criar_perfil_hidrocare gravava na coluna "ra", que não existe
--     mais em usuarios (o cadastro falhava com "column ra does not exist");
--  2) o perfil era decidido por um campo digitado no formulário, e não pelo
--     e-mail. Agora vale a mesma regra do is_admin(): pub...@mg.senac.br
--     = professor; qualquer outro e-mail institucional = estudante;
--  3) usuarios.email tinha como valor padrão o TEXTO 'NOT NULL' (provável
--     engano ao criar a coluna). Com UNIQUE(email), o 2º cadastro sem e-mail
--     daria erro de duplicidade;
--  4) a função antiga criar_usuario_hidrocare também gravava em "ra" e não
--     gravava e-mail; foi removida.
-- =====================================================================

-- 1. Tirar o valor padrão errado e corrigir linhas que já ficaram com ele
alter table public.usuarios alter column email drop default;

update public.usuarios u
   set email = a.email
  from auth.users a
 where a.id = u.id and u.email = 'NOT NULL';

-- 2. Remover gatilhos antigos de cadastro (qualquer nome) e a função antiga
do $$
declare r record;
begin
  for r in
    select t.tgname
      from pg_trigger t
      join pg_proc p on p.oid = t.tgfoid
     where t.tgrelid = 'auth.users'::regclass
       and not t.tgisinternal
       and p.proname in ('criar_perfil_hidrocare', 'criar_usuario_hidrocare')
  loop
    execute format('drop trigger %I on auth.users', r.tgname);
  end loop;
end $$;

drop function if exists public.criar_usuario_hidrocare();

-- 3. Função nova: cria a linha em usuarios a cada cadastro no Auth
create or replace function public.criar_perfil_hidrocare()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_nome text;
begin
  v_nome := nullif(trim(coalesce(new.raw_user_meta_data ->> 'nome', '')), '');
  if v_nome is null then
    v_nome := split_part(new.email, '@', 1);      -- sem nome informado: usa o começo do e-mail
  end if;

  insert into public.usuarios (id, nome, email, perfil)
  values (
    new.id,
    v_nome,
    new.email,
    case when new.email ~* '^pub[^@]*@mg\.senac\.br$' then 'professor' else 'estudante' end
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists criar_perfil_no_cadastro on auth.users;
create trigger criar_perfil_no_cadastro
  after insert on auth.users
  for each row execute function public.criar_perfil_hidrocare();

-- 4. Quem já existe no Auth mas não tem linha em usuarios (ex.: contas criadas
--    pelo painel enquanto o gatilho estava quebrado) ganha o perfil agora
insert into public.usuarios (id, nome, email, perfil)
select a.id,
       coalesce(nullif(trim(a.raw_user_meta_data ->> 'nome'), ''), split_part(a.email, '@', 1)),
       a.email,
       case when a.email ~* '^pub[^@]*@mg\.senac\.br$' then 'professor' else 'estudante' end
  from auth.users a
 where a.email is not null
   and not exists (select 1 from public.usuarios u where u.id = a.id)
on conflict do nothing;
