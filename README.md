# Projeto de Banco de Dados - Views e Triggers

## Descrição do Projeto
Este repositório contém a implementação de views e triggers para um cenário fictício de uma empresa e um e-commerce. O objetivo é personalizar o acesso a informações no banco de dados por meio de views, e criar triggers para realizar ações automáticas em momentos específicos de inserção, atualização ou remoção de dados.

## Estrutura do Projeto
O projeto está dividido em duas partes principais:

## Parte 1 – Personalizando Acessos com Views
Nesta parte, foram criadas views para diferentes cenários de consulta, facilitando o acesso a informações específicas e limitando os dados expostos aos usuários. Além disso, foram configuradas permissões para diferentes tipos de usuários (gerente e empregado), garantindo que cada um tenha acesso apenas às informações necessárias.

### Views Criadas:
#### Número de empregados por departamento e localidade:

Exibe o número total de empregados em cada departamento por localidade.

CREATE VIEW empregados_por_departamento_localidade AS
SELECT departamento, localidade, COUNT(*) AS num_empregados
FROM empregados
GROUP BY departamento, localidade;

#### Lista de departamentos e seus gerentes:
Mostra uma relação entre cada departamento e seu respectivo gerente.

CREATE VIEW departamentos_gerentes AS
SELECT d.nome AS departamento, e.nome AS gerente
FROM departamentos d
JOIN empregados e ON d.id_gerente = e.id_empregado;

#### Projetos com maior número de empregados (ordenado de forma decrescente):
Lista os projetos com maior número de empregados, ordenados de forma decrescente.

CREATE VIEW projetos_com_mais_empregados AS
SELECT p.nome AS projeto, COUNT(e.id_empregado) AS num_empregados
FROM projetos p
JOIN empregados_projetos ep ON p.id_projeto = ep.id_projeto
JOIN empregados e ON ep.id_empregado = e.id_empregado
GROUP BY p.nome
ORDER BY num_empregados DESC;

#### Lista de projetos, departamentos e gerentes:
Exibe a lista de projetos, seus departamentos e gerentes responsáveis.

CREATE VIEW projetos_departamentos_gerentes AS
SELECT p.nome AS projeto, d.nome AS departamento, e.nome AS gerente
FROM projetos p
JOIN departamentos d ON p.id_departamento = d.id_departamento
JOIN empregados e ON d.id_gerente = e.id_empregado;

#### Quais empregados possuem dependentes e se são gerentes:
Lista quais empregados possuem dependentes e informa se são gerentes ou não.

CREATE VIEW empregados_com_dependentes_e_se_sao_gerentes AS
SELECT e.nome AS empregado, IF(e.id_empregado = d.id_gerente, 'Sim', 'Não') AS e_gerente
FROM empregados e
LEFT JOIN dependentes dep ON e.id_empregado = dep.id_empregado
LEFT JOIN departamentos d ON e.id_empregado = d.id_gerente
WHERE dep.id_dependente IS NOT NULL;

### Definição de Permissões de Acesso
Usuários e Permissões:
Tem acesso às informações de empregados e departamentos.

CREATE USER 'gerente'@'localhost' IDENTIFIED BY 'senha_gerente';
GRANT SELECT ON banco_de_dados.empregados TO 'gerente'@'localhost';
GRANT SELECT ON banco_de_dados.departamentos TO 'gerente'@'localhost';
GRANT SELECT ON banco_de_dados.departamentos_gerentes TO 'gerente'@'localhost';
Usuário Empregado:

Usuário Gerente:
Acesso apenas às informações de empregados, sem acesso a dados de departamentos ou gerentes.

CREATE USER 'empregado'@'localhost' IDENTIFIED BY 'senha_empregado';
GRANT SELECT ON banco_de_dados.empregados TO 'empregado'@'localhost';
REVOKE SELECT ON banco_de_dados.departamentos FROM 'empregado'@'localhost';
REVOKE SELECT ON banco_de_dados.departamentos_gerentes FROM 'empregado'@'localhost';

## Parte 2 – Criando Triggers para o Cenário de E-commerce
Nesta parte, foram criados triggers que são ativados antes da remoção e atualização de dados no banco de dados de um cenário de e-commerce. Esses triggers garantem a manutenção de informações críticas, como o histórico de usuários e atualizações salariais.

### Triggers Criadas:

#### Trigger Before Delete:
Ao excluir um usuário, os dados são transferidos para uma tabela de histórico antes da remoção.

CREATE TRIGGER before_user_delete
BEFORE DELETE ON usuarios
FOR EACH ROW
BEGIN
    INSERT INTO usuarios_historico (id_usuario, nome, email, data_exclusao)
    VALUES (OLD.id_usuario, OLD.nome, OLD.email, NOW());
END;

#### Trigger Before Update:
Antes de atualizar o salário de um colaborador, o valor anterior é registrado em uma tabela de histórico.

CREATE TRIGGER before_salario_update
BEFORE UPDATE ON empregados
FOR EACH ROW
BEGIN
    IF NEW.salario <> OLD.salario THEN
        INSERT INTO salario_historico (id_empregado, salario_antigo, salario_novo, data_atualizacao)
        VALUES (OLD.id_empregado, OLD.salario, NEW.salario, NOW());
    END IF;
END;

#### Trigger Before Insert:
Ao inserir um novo colaborador, um registro é criado no log de colaboradores.

CREATE TRIGGER before_novo_colaborador_insert
BEFORE INSERT ON empregados
FOR EACH ROW
BEGIN
    INSERT INTO colaboradores_log (nome, data_contratacao)
    VALUES (NEW.nome, NOW());
END;

### Tecnologias Utilizadas
MySQL: Sistema de gerenciamento de banco de dados relacional.
SQL: Linguagem de consulta estruturada para manipulação dos dados.
