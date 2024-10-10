-- Views Criadas
-- Número de empregados por departamento e localidade:
CREATE VIEW empregados_por_departamento_localidade AS
SELECT departamento, localidade, COUNT(*) AS num_empregados
FROM empregados
GROUP BY departamento, localidade;

-- Lista de departamentos e seus gerentes:
CREATE VIEW departamentos_gerentes AS
SELECT d.nome AS departamento, e.nome AS gerente
FROM departamentos d
JOIN empregados e ON d.id_gerente = e.id_empregado;

-- Projetos com maior número de empregados (ordenado de forma decrescente):
CREATE VIEW projetos_com_mais_empregados AS
SELECT p.nome AS projeto, COUNT(e.id_empregado) AS num_empregados
FROM projetos p
JOIN empregados_projetos ep ON p.id_projeto = ep.id_projeto
JOIN empregados e ON ep.id_empregado = e.id_empregado
GROUP BY p.nome
ORDER BY num_empregados DESC;

-- Lista de projetos, departamentos e gerentes:
CREATE VIEW projetos_departamentos_gerentes AS
SELECT p.nome AS projeto, d.nome AS departamento, e.nome AS gerente
FROM projetos p
JOIN departamentos d ON p.id_departamento = d.id_departamento
JOIN empregados e ON d.id_gerente = e.id_empregado;

-- Quais empregados possuem dependentes e se são gerentes:
CREATE VIEW empregados_com_dependentes_e_se_sao_gerentes AS
SELECT e.nome AS empregado, IF(e.id_empregado = d.id_gerente, 'Sim', 'Não') AS e_gerente
FROM empregados e
LEFT JOIN dependentes dep ON e.id_empregado = dep.id_empregado
LEFT JOIN departamentos d ON e.id_empregado = d.id_gerente
WHERE dep.id_dependente IS NOT NULL;

 -- DEFINIÇÃO DE PERMISSÕES DE ACESSO 
-- Criação de Usuários e Permissões:

-- Usuário Gerente:
-- Este usuário terá acesso às informações de empregados e departamentos.
CREATE USER 'gerente'@'localhost' IDENTIFIED BY 'senha_gerente';

-- Permissões de acesso a empregados e departamentos
GRANT SELECT ON banco_de_dados.empregados TO 'gerente'@'localhost';
GRANT SELECT ON banco_de_dados.departamentos TO 'gerente'@'localhost';
GRANT SELECT ON banco_de_dados.departamentos_gerentes TO 'gerente'@'localhost';

-- Usuário Empregado:
-- Este usuário terá acesso limitado às informações de empregados, mas não poderá ver dados relacionados aos departamentos ou gerentes.
CREATE USER 'empregado'@'localhost' IDENTIFIED BY 'senha_empregado';

-- Permissões de acesso apenas a empregados
GRANT SELECT ON banco_de_dados.empregados TO 'empregado'@'localhost';

-- Nenhum acesso a informações de departamentos ou gerentes
REVOKE SELECT ON banco_de_dados.departamentos FROM 'empregado'@'localhost';
REVOKE SELECT ON banco_de_dados.departamentos_gerentes FROM 'empregado'@'localhost';

-- Observação:
-- As views criadas funcionam como "tabelas virtuais" que facilitam o acesso a informações específicas sem expor toda a base de dados. O controle de acesso é definido com base no nível de privilégio do usuário.

-- PARTE 2 - CRIANDO GATILHOS (TRIGGERS) PARA O CENÁRIO DE E-COMMERCE
-- Triggers Criadas
	
    -- 1.Trigger Before Delete:
		-- Quando um usuário exclui sua conta, os dados são mantidos em uma tabela de log para evitar a perda de informações valiosas.
CREATE TRIGGER before_user_delete
BEFORE DELETE ON usuarios
FOR EACH ROW
BEGIN
    INSERT INTO usuarios_historico (id_usuario, nome, email, data_exclusao)
    VALUES (OLD.id_usuario, OLD.nome, OLD.email, NOW()),
END;
-- Esta trigger armazena as informações do usuário que está sendo excluído na tabela usuarios_historico, juntamente com a data de exclusão.

-- 2. Trigger Before Update:
-- Ao atualizar o salário de um colaborador, o valor anterior é registrado em um log para auditoria.
CREATE TRIGGER before_salario_update
BEFORE UPDATE ON empregados
FOR EACH ROW
BEGIN
    IF NEW.salario <> OLD.salario THEN
        INSERT INTO salario_historico (id_empregado, salario_antigo, salario_novo, data_atualizacao)
        VALUES (OLD.id_empregado, OLD.salario, NEW.salario, NOW()),
    END IF,
END;
-- Este gatilho captura qualquer atualização no campo salario e registra o valor antigo e o novo na tabela salario_historico.

-- 3. Trigger Before Insert:
-- Quando um novo colaborador é inserido no sistema, a trigger é ativada para registrar essa ação no log.
CREATE TRIGGER before_novo_colaborador_insert
BEFORE INSERT ON empregados
FOR EACH ROW
BEGIN
    INSERT INTO colaboradores_log (nome, data_contratacao)
    VALUES (NEW.nome, NOW()),
END;
-- Esta trigger armazena o nome do novo colaborador e a data de contratação na tabela colaboradores_log.