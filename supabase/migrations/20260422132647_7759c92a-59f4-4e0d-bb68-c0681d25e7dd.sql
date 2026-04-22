DELETE FROM public.saved_rotulos
WHERE (nr_requisicao = '10495' OR nr_requisicao = '010495')
  AND item_id LIKE '%-B-%';