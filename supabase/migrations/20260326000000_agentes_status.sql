-- Tabela para registro de status dos agentes de impressão
CREATE TABLE IF NOT EXISTS public.agentes_status (
  id TEXT PRIMARY KEY,           -- 'edi' | 'daniel'
  nome TEXT NOT NULL,            -- 'PC da Edi' | 'PC do Daniel'
  url TEXT DEFAULT '',           -- URL ngrok atual
  hostname TEXT DEFAULT '',      -- hostname do Windows
  versao TEXT DEFAULT '',        -- versão do agente
  status TEXT DEFAULT 'offline', -- 'online' | 'offline'
  ultimo_ping TIMESTAMPTZ,       -- último heartbeat
  atualizado_em TIMESTAMPTZ DEFAULT now()
);

-- Inserir registros iniciais
INSERT INTO public.agentes_status (id, nome, status) VALUES
  ('edi',    'PC da Edi',    'offline'),
  ('daniel', 'PC do Daniel', 'offline')
ON CONFLICT (id) DO NOTHING;

-- Permitir leitura e escrita para anon (os agentes usam a chave anon)
ALTER TABLE public.agentes_status ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Leitura publica agentes" ON public.agentes_status
  FOR SELECT USING (true);

CREATE POLICY "Agentes podem atualizar proprio status" ON public.agentes_status
  FOR UPDATE USING (true);

CREATE POLICY "Agentes podem inserir status" ON public.agentes_status
  FOR INSERT WITH CHECK (true);
