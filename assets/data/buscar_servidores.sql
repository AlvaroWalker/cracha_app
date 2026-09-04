-- Busca de servidores ignorando acentos (ex: "JOAO" acha "JOÃO").
--
-- COMO APLICAR: Supabase Dashboard > SQL Editor > colar e rodar (uma vez só).
-- O app detecta a função sozinho; sem ela, a busca segue no modo atual (ilike).

create extension if not exists unaccent;

create or replace function buscar_servidores(termo text, limite int default 8)
returns table (
  nome text,
  cargo text,
  secretaria text
)
language sql
stable
as $$
  select s.nome, s.cargo, s.secretaria
  from servidores s
  where unaccent(s.nome) ilike '%' || unaccent(termo) || '%'
     or unaccent(s.cargo) ilike '%' || unaccent(termo) || '%'
     or unaccent(s.secretaria) ilike '%' || unaccent(termo) || '%'
  limit limite;
$$;
