Desafio SQL – Views, Permissões e Triggers
Este repositório contém um script completo em MySQL que resolve dois desafios:

Parte 1 – Views e Permissões
Criação de views personalizadas para um cenário empresarial, incluindo:

Número de empregados por departamento e localidade
Lista de departamentos e seus gerentes
Projetos com maior número de empregados
Lista de projetos, departamentos e gerentes
Empregados com dependentes e se são gerentes
Também são criados dois usuários com permissões específicas:

gerente: acesso total às views
empregado: acesso limitado

Parte 2 – Triggers (Gatilhos)
Cenário de e-commerce com dois gatilhos:

BEFORE DELETE: salva dados de usuários excluídos
BEFORE UPDATE: registra histórico de alterações salariais
