-- database/init.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ============================================
-- 1. USUÁRIOS E AUTENTICAÇÃO
-- ============================================
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    senha VARCHAR(255) NOT NULL,
    nome VARCHAR(150) NOT NULL,
    tipo VARCHAR(20) NOT NULL DEFAULT 'COMUM' CHECK (tipo IN ('COMUM', 'ONG', 'EMPRESA', 'CIENTISTA')),
    
    -- Perfil
    avatar_url VARCHAR(500),
    biografia TEXT,
    telefone VARCHAR(20),
    cidade VARCHAR(100),
    estado VARCHAR(2),
    
    -- Status
    verificado BOOLEAN DEFAULT FALSE,
    ativo BOOLEAN DEFAULT TRUE,
    reputacao INT DEFAULT 0,
    
    -- Contadores
    problemas_reportados INT DEFAULT 0,
    problemas_resolvidos INT DEFAULT 0,
    eventos_participados INT DEFAULT 0,
    
    -- Timestamps
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_login TIMESTAMP
);

-- Dados específicos por tipo (opcional, pode ser JSON)
CREATE TABLE ongs (
    usuario_id UUID PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    cnpj VARCHAR(18) UNIQUE,
    area_atuacao VARCHAR(100),
    website VARCHAR(200),
    instagram VARCHAR(100),
    link_doacao VARCHAR(500)
);

CREATE TABLE empresas (
    usuario_id UUID PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    cnpj VARCHAR(18) UNIQUE,
    ramo VARCHAR(100),
    responsabilidade_social BOOLEAN DEFAULT FALSE
);

CREATE TABLE cientistas (
    usuario_id UUID PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
    instituicao VARCHAR(200),
    formacao VARCHAR(200),
    lattes_url VARCHAR(500)
);

-- ============================================
-- 2. CATEGORIAS (para mapa e blog)
-- ============================================
CREATE TABLE categorias (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('PROBLEMA', 'SOLUCAO', 'INFORMACAO')),
    icone VARCHAR(50),
    cor_hex VARCHAR(7) DEFAULT '#3498db',
    ordem INT DEFAULT 0,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 3. MARCADORES DO MAPA (core da aplicação)
-- ============================================
CREATE TABLE marcadores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT NOT NULL,
    
    -- Localização (OBRIGATÓRIO para mapa)
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    ponto_geografico GEOMETRY(Point, 4326) GENERATED ALWAYS AS (ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)) STORED,
    endereco TEXT,
    bairro VARCHAR(100),
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    
    -- Classificação
    categoria_id UUID REFERENCES categorias(id),
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('PROBLEMA', 'SOLUCAO', 'EVENTO', 'INFORMACAO')),
    
    -- Status do marcador
    status VARCHAR(20) DEFAULT 'ATIVO' CHECK (status IN ('ATIVO', 'RESOLVIDO', 'ARQUIVADO', 'EM_ANDAMENTO')),
    urgencia INT DEFAULT 1 CHECK (urgencia BETWEEN 1 AND 5),
    
    -- Engajamento
    votos_positivos INT DEFAULT 0,
    votos_negativos INT DEFAULT 0,
    visualizacoes INT DEFAULT 0,
    compartilhamentos INT DEFAULT 0,
    
    -- Relacionamentos
    usuario_id UUID REFERENCES usuarios(id) NOT NULL,
    
    -- Timestamps
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    data_ocorrencia TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Para controle
    uuid_publico VARCHAR(10) UNIQUE DEFAULT substr(md5(random()::text), 1, 10)
);

-- Índices ESPECIAIS para mapa (crítico para performance)
CREATE INDEX idx_marcadores_ponto ON marcadores USING GIST(ponto_geografico);
CREATE INDEX idx_marcadores_cidade_tipo ON marcadores(cidade, tipo, status);
CREATE INDEX idx_marcadores_urgencia ON marcadores(urgencia DESC) WHERE tipo = 'PROBLEMA';
CREATE INDEX idx_marcadores_criacao ON marcadores(criado_em DESC);

-- ============================================
-- 4. MÍDIAS DOS MARCADORES (imagens no mapa)
-- ============================================
CREATE TABLE midias_marcador (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marcador_id UUID REFERENCES marcadores(id) ON DELETE CASCADE,
    tipo VARCHAR(20) CHECK (tipo IN ('IMAGEM', 'VIDEO', 'DOCUMENTO')),
    url VARCHAR(500) NOT NULL,
    url_miniatura VARCHAR(500),
    legenda TEXT,
    ordem INT DEFAULT 0,
    
    -- Metadata
    nome_arquivo VARCHAR(200),
    tipo_mime VARCHAR(100),
    tamanho_bytes BIGINT,
    
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_midias_marcador ON midias_marcador(marcador_id);

-- ============================================
-- 5. INTERAÇÕES (votos, comentários, etc)
-- ============================================
CREATE TABLE votos_marcador (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marcador_id UUID REFERENCES marcadores(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id),
    tipo VARCHAR(10) CHECK (tipo IN ('POSITIVO', 'NEGATIVO')),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(marcador_id, usuario_id)
);

CREATE TABLE comentarios (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    marcador_id UUID REFERENCES marcadores(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id),
    comentario TEXT NOT NULL,
    
    -- Para respostas
    comentario_pai_id UUID REFERENCES comentarios(id) ON DELETE CASCADE,
    
    -- Engajamento
    curtidas INT DEFAULT 0,
    
    -- Status
    removido BOOLEAN DEFAULT FALSE,
    
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comentarios_marcador ON comentarios(marcador_id, criado_em DESC);
CREATE INDEX idx_comentarios_usuario ON comentarios(usuario_id);

CREATE TABLE curtidas_comentario (
    comentario_id UUID REFERENCES comentarios(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (comentario_id, usuario_id)
);

-- ============================================
-- 6. BLOG/REDE SOCIAL (integrado com mapa)
-- ============================================
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(200) NOT NULL,
    conteudo TEXT NOT NULL,
    resumo TEXT,
    
    -- Relacionamento com mapa
    marcador_id UUID REFERENCES marcadores(id) ON DELETE SET NULL,
    
    -- Categorização
    tipo_post VARCHAR(20) CHECK (tipo_post IN ('BLOG', 'NOTICIA', 'ARTIGO', 'TUTORIAL')),
    tags TEXT[],
    
    -- Autor
    autor_id UUID REFERENCES usuarios(id) NOT NULL,
    
    -- Status
    publicado BOOLEAN DEFAULT FALSE,
    destaque BOOLEAN DEFAULT FALSE,
    
    -- Engajamento
    visualizacoes INT DEFAULT 0,
    curtidas INT DEFAULT 0,
    compartilhamentos INT DEFAULT 0,
    
    -- Timestamps
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    publicado_em TIMESTAMP
);

CREATE INDEX idx_posts_autor ON posts(autor_id, publicado_em DESC);
CREATE INDEX idx_posts_destaque ON posts(destaque) WHERE destaque = TRUE AND publicado = TRUE;

-- Imagens dos posts
CREATE TABLE imagens_post (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    url VARCHAR(500) NOT NULL,
    legenda TEXT,
    ordem INT DEFAULT 0,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Curtidas nos posts
CREATE TABLE curtidas_post (
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id),
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, usuario_id)
);

-- Comentários nos posts
CREATE TABLE comentarios_post (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id),
    comentario TEXT NOT NULL,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 7. EVENTOS (no mapa também)
-- ============================================
CREATE TABLE eventos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    titulo VARCHAR(200) NOT NULL,
    descricao TEXT NOT NULL,
    
    -- Localização (pode ter ou não)
    marcador_id UUID REFERENCES marcadores(id) ON DELETE SET NULL,
    endereco TEXT,
    
    -- Datas
    data_inicio TIMESTAMP NOT NULL,
    data_fim TIMESTAMP,
    
    -- Organização
    organizador_id UUID REFERENCES usuarios(id),
    tipo_evento VARCHAR(30) CHECK (tipo_evento IN ('LIMPEZA', 'PALESTRA', 'WORKSHOP', 'ADOÇÃO', 'MUTIRAO', 'PROTESTO')),
    
    -- Informações práticas
    max_participantes INT,
    link_inscricao VARCHAR(500),
    
    -- Status
    status VARCHAR(20) DEFAULT 'PLANEJADO' CHECK (status IN ('PLANEJADO', 'CONFIRMADO', 'CANCELADO', 'REALIZADO')),
    
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inscricoes_evento (
    evento_id UUID REFERENCES eventos(id) ON DELETE CASCADE,
    usuario_id UUID REFERENCES usuarios(id),
    data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'INSCRITO' CHECK (status IN ('INSCRITO', 'CONFIRMADO', 'CANCELADO', 'PARTICIPOU')),
    PRIMARY KEY (evento_id, usuario_id)
);

-- ============================================
-- 8. NOTIFICAÇÕES (simples, pode evoluir)
-- ============================================
CREATE TABLE notificacoes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    titulo VARCHAR(200) NOT NULL,
    mensagem TEXT NOT NULL,
    tipo VARCHAR(30) CHECK (tipo IN ('VOTO', 'COMENTARIO', 'EVENTO', 'SISTEMA', 'ATUALIZACAO')),
    
    -- Link para ação
    referencia_tipo VARCHAR(50),
    referencia_id UUID,
    url_acao VARCHAR(500),
    
    -- Status
    lida BOOLEAN DEFAULT FALSE,
    enviada BOOLEAN DEFAULT FALSE,
    
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    lida_em TIMESTAMP
);

CREATE INDEX idx_notificacoes_usuario ON notificacoes(usuario_id, lida, criado_em DESC);

-- ============================================
-- 9. SEGUIMENTOS (rede social básica)
-- ============================================
CREATE TABLE seguimentos (
    seguidor_id UUID REFERENCES usuarios(id),
    seguido_id UUID REFERENCES usuarios(id),
    data_seguimento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (seguidor_id, seguido_id),
    CHECK (seguidor_id != seguido_id)
);

-- ============================================
-- 10. SESSÕES/TOKENS
-- ============================================
CREATE TABLE sessoes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    token VARCHAR(500) UNIQUE NOT NULL,
    refresh_token VARCHAR(500) UNIQUE,
    expira_em TIMESTAMP NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    ativo BOOLEAN DEFAULT TRUE,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- 11. AUDITORIA (logs importantes)
-- ============================================
CREATE TABLE logs_auditoria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    acao VARCHAR(50) NOT NULL,
    usuario_id UUID REFERENCES usuarios(id),
    ip_address VARCHAR(45),
    user_agent TEXT,
    dados JSONB,
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_logs_acao ON logs_auditoria(acao, criado_em DESC);

-- ============================================
-- DADOS INICIAIS
-- ============================================

-- Categorias padrão
INSERT INTO categorias (nome, descricao, tipo, icone, cor_hex, ordem) VALUES
-- Problemas
('Buraco na Rua', 'Problemas com asfalto e calçadas', 'PROBLEMA', '🚧', '#e74c3c', 1),
('Lixo Acumulado', 'Lixo, entulho e descarte irregular', 'PROBLEMA', '🗑️', '#d35400', 2),
('Iluminação', 'Postes queimados e áreas escuras', 'PROBLEMA', '💡', '#f39c12', 3),
('Água/Esgoto', 'Vazamentos e problemas hídricos', 'PROBLEMA', '💧', '#3498db', 4),
('Animais', 'Maus-tratos e animais abandonados', 'PROBLEMA', '🐾', '#8e44ad', 5),

-- Soluções
('Parque/Área Verde', 'Áreas de lazer bem cuidadas', 'SOLUCAO', '🌳', '#27ae60', 6),
('Infraestrutura Nova', 'Melhorias recentes na cidade', 'SOLUCAO', '🛠️', '#2ecc71', 7),
('Ação Comunitária', 'Iniciativas da comunidade', 'SOLUCAO', '🤝', '#16a085', 8),

-- Informações
('Evento', 'Eventos e encontros', 'INFORMACAO', '🎪', '#9b59b6', 9),
('Dica Ambiental', 'Informações úteis', 'INFORMACAO', '💡', '#34495e', 10);

-- Usuário admin padrão (senha: admin123)
INSERT INTO usuarios (email, senha, nome, tipo, verificado, cidade, estado) VALUES
('admin@econexa.com', '$2a$10$YourHashedPasswordHere', 'Administrador ECONEXA', 'COMUM', TRUE, 'São Paulo', 'SP');

-- Alguns marcadores de exemplo
INSERT INTO marcadores (titulo, descricao, latitude, longitude, cidade, estado, categoria_id, tipo, usuario_id, urgencia) VALUES
('Buraco na Av. Paulista', 'Buraco grande perto do MASP', -23.5614, -46.6561, 'São Paulo', 'SP', 
 (SELECT id FROM categorias WHERE nome = 'Buraco na Rua'), 'PROBLEMA',
 (SELECT id FROM usuarios WHERE email = 'admin@econexa.com'), 3),

('Parque Ibirapuera Limpo', 'Parque muito bem cuidado hoje', -23.5875, -46.6576, 'São Paulo', 'SP',
 (SELECT id FROM categorias WHERE nome = 'Parque/Área Verde'), 'SOLUCAO',
 (SELECT id FROM usuarios WHERE email = 'admin@econexa.com'), 1);

-- ============================================
-- VIEWS ÚTEIS PARA DASHBOARD
-- ============================================

-- View para mapa (com todas as informações necessárias)
CREATE VIEW vw_mapa_completo AS
SELECT 
    m.*,
    c.nome as categoria_nome,
    c.icone as categoria_icone,
    c.cor_hex as categoria_cor,
    u.nome as usuario_nome,
    u.avatar_url as usuario_avatar,
    COUNT(DISTINCT v.id) as total_votos,
    COUNT(DISTINCT com.id) as total_comentarios,
    ARRAY_AGG(DISTINCT mm.url) FILTER (WHERE mm.tipo = 'IMAGEM') as imagens
FROM marcadores m
JOIN categorias c ON m.categoria_id = c.id
JOIN usuarios u ON m.usuario_id = u.id
LEFT JOIN votos_marcador v ON m.id = v.marcador_id
LEFT JOIN comentarios com ON m.id = com.marcador_id AND com.removido = FALSE
LEFT JOIN midias_marcador mm ON m.id = mm.marcador_id
WHERE m.status = 'ATIVO'
GROUP BY m.id, c.id, u.id;

-- View para estatísticas rápidas
CREATE VIEW vw_estatisticas AS
SELECT 
    (SELECT COUNT(*) FROM usuarios WHERE ativo = TRUE) as usuarios_ativos,
    (SELECT COUNT(*) FROM marcadores WHERE tipo = 'PROBLEMA' AND status = 'ATIVO') as problemas_ativos,
    (SELECT COUNT(*) FROM marcadores WHERE tipo = 'SOLUCAO') as solucoes_registradas,
    (SELECT COUNT(*) FROM eventos WHERE status IN ('PLANEJADO', 'CONFIRMADO')) as eventos_ativos,
    (SELECT COUNT(*) FROM posts WHERE publicado = TRUE) as posts_publicados,
    (SELECT cidade FROM marcadores GROUP BY cidade ORDER BY COUNT(*) DESC LIMIT 1) as cidade_mais_ativa;

-- ============================================
-- FUNÇÕES ÚTEIS
-- ============================================

-- Função para calcular distância entre pontos (em km)
CREATE OR REPLACE FUNCTION calcular_distancia_km(
    lat1 DECIMAL, lng1 DECIMAL, 
    lat2 DECIMAL, lng2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    R DECIMAL := 6371; -- Raio da Terra em km
    dlat DECIMAL := RADIANS(lat2 - lat1);
    dlng DECIMAL := RADIANS(lng2 - lng1);
    a DECIMAL;
    c DECIMAL;
BEGIN
    a := SIN(dlat/2) * SIN(dlat/2) +
         COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
         SIN(dlng/2) * SIN(dlng/2);
    c := 2 * ATAN2(SQRT(a), SQRT(1-a));
    RETURN R * c;
END;
$$ LANGUAGE plpgsql;

-- Função para buscar marcadores próximos
CREATE OR REPLACE FUNCTION buscar_marcadores_proximos(
    p_latitude DECIMAL,
    p_longitude DECIMAL,
    p_raio_km DECIMAL DEFAULT 10
) RETURNS SETOF marcadores AS $$
BEGIN
    RETURN QUERY
    SELECT m.*
    FROM marcadores m
    WHERE calcular_distancia_km(p_latitude, p_longitude, m.latitude, m.longitude) <= p_raio_km
      AND m.status = 'ATIVO'
    ORDER BY 
        calcular_distancia_km(p_latitude, p_longitude, m.latitude, m.longitude),
        m.urgencia DESC;
END;
$$ LANGUAGE plpgsql;

-- Trigger para atualizar contadores automaticamente
CREATE OR REPLACE FUNCTION atualizar_contador_votos()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE marcadores 
        SET votos_positivos = votos_positivos + (CASE WHEN NEW.tipo = 'POSITIVO' THEN 1 ELSE 0 END),
            votos_negativos = votos_negativos + (CASE WHEN NEW.tipo = 'NEGATIVO' THEN 1 ELSE 0 END)
        WHERE id = NEW.marcador_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE marcadores 
        SET votos_positivos = votos_positivos - (CASE WHEN OLD.tipo = 'POSITIVO' THEN 1 ELSE 0 END),
            votos_negativos = votos_negativos - (CASE WHEN OLD.tipo = 'NEGATIVO' THEN 1 ELSE 0 END)
        WHERE id = OLD.marcador_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_atualizar_votos
AFTER INSERT OR DELETE ON votos_marcador
FOR EACH ROW EXECUTE FUNCTION atualizar_contador_votos();

SELECT '✅ Banco de dados ECONEXA criado com sucesso!' as mensagem;