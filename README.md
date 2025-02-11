# Banco_de_Dados_SQL_Server
Estrutura de Banco de Dados SQL Server com Scripts de apoio


# Pasta Administração
- Pasta com scripts de apoio para a Administração do Banco de Dados

Arquivos:

## Backup_Diferencial_DBA_JOB.sql

- Descrição Geral: Este script foi desenvolvido para criar e gerenciar rotinas de backup diferencial e full para bancos de dados no SQL Server. Ele inclui stored procedures para realizar backups diferenciais e completos, além de configurar um job no SQL Server Agent para automatizar essas tarefas.

### Explicação do Funcionamento
1. Stored Procedure stpBackup_Diferencial_Disco :
- Esta stored procedure realiza backups diferenciais para todos os bancos de dados online, exceto os bancos de sistema (tempdb, msdb, master, model).
- Ela utiliza uma tabela temporária para armazenar os nomes dos bancos de dados e processa cada um em um loop.
2. Stored Procedure stpBackup_Diferencial_Database :
- Esta stored procedure realiza o backup diferencial de um banco de dados específico.
- Permite adicionar uma descrição ao backup, se necessário.
3. Stored Procedure stpBackup_Novas_Databases :
- Esta stored procedure realiza backups full para bancos de dados criados no mesmo dia.
- Utiliza uma tabela temporária para identificar os bancos de dados recém-criados.
4. Job no SQL Server Agent :
- O job é configurado para executar automaticamente as stored procedures de backup diferencial e full.
- Ele está agendado para rodar semanalmente nos dias especificados.

### Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que os diretórios de backup (F:\Backups\Diferencial\ e \\C\backup_sql\Full\) existam.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.

## Backup_Full_DBA_JOB.sql

- Descrição Geral: Este script foi desenvolvido para criar e gerenciar rotinas de backup full para bancos de dados no SQL Server. Ele inclui stored procedures para realizar backups completos, além de configurar um job no SQL Server Agent para automatizar essas tarefas.

### Explicação do Funcionamento
1. Stored Procedure stpBackup_FULL_Database :
- Esta stored procedure realiza o backup full de um banco de dados específico.
- Permite adicionar uma descrição ao backup, se necessário.
- Utiliza a opção COMPRESSION para reduzir o tamanho do arquivo de backup.
2. Stored Procedure stpBackup_Databases_Disco :
- Esta stored procedure realiza backups full para todos os bancos de dados online, exceto o banco tempdb.
- Utiliza uma tabela temporária para armazenar os nomes dos bancos de dados e processa cada um em um loop.
- Inclui comentários para futuras implementações, como exclusão de bases específicas ou backups somente aos domingos.
3. Job no SQL Server Agent :
- O job é configurado para executar automaticamente a stored procedure stpBackup_Databases_Disco.
- Está agendado para rodar diariamente às 10:00 AM.

### Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que o diretório de backup (D:\Backup\FULL\) exista.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.

## Detach_Attach_Databases_DBA_Tools.sql

- Descrição Geral: Este script foi desenvolvido para gerar comandos SQL que permitem desanexar (detach) e anexar (attach) bancos de dados no SQL Server. Ele é útil em cenários onde é necessário mover arquivos de banco de dados ou realizar manutenções específicas.

### Explicação do Funcionamento
1. Desanexação (Detach) :
- O primeiro bloco de código gera comandos SQL para desanexar todos os bancos de dados online, exceto os bancos de sistema (tempdb, master, model, msdb).
- Antes de executar o comando sp_detach_db, o banco de dados é colocado no modo SINGLE_USER com rollback imediato para garantir que nenhuma conexão esteja ativa.
- O comando verifica se o banco de dados está online antes de tentar desanexá-lo.
2. Anexação (Attach) :
- O segundo bloco de código gera comandos SQL para anexar bancos de dados previamente desanexados.
- O comando verifica se o banco de dados já existe no servidor antes de tentar anexá-lo.
- Utiliza os caminhos dos arquivos primários (.mdf) e secundários (.ldf) para reconstruir o banco de dados.
- Caso exista um terceiro arquivo (por exemplo, um arquivo .ndf), ele também será incluído no comando de anexação.

### Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Copie os comandos gerados para desanexar ou anexar os bancos de dados conforme necessário.
3. Certifique-se de que os caminhos dos arquivos de banco de dados estão corretos antes de executar os comandos de anexação.

## Cleanup_Old_Records_DBA_Tools.sql

- Descrição Geral: Este script foi desenvolvido para criar uma rotina de limpeza de registros antigos em tabelas específicas do banco de dados. Ele inclui uma stored procedure que exclui registros com base em um período de retenção definido e configura um job no SQL Server Agent para automatizar essa tarefa.

### Explicação do Funcionamento
1. Stored Procedure stpExclui_Registros_Antigos :
- Esta stored procedure exclui registros antigos de várias tabelas com base em um período de retenção definido (em dias).
- As tabelas afetadas incluem Registro_Contador, Resultado_WhoisActive, Historico_Tamanho_Tabela Historico_Utilizacao_Indices, Historico_Fragmentacao_Indice, Traces, Historico_Waits_Stats e Historico_Utilizacao_Arquivo.
- O período de retenção é configurável para cada tabela.
2. Job no SQL Server Agent :
- O job é configurado para executar automaticamente a stored procedure stpExclui_Registros_Antigos.
- Está agendado para rodar diariamente às 23:50 PM.

### Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que as tabelas mencionadas no script existam no banco de dados DBA_Tools.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.

## Clean_Error_Log_DBA_Tools.sql

- Descrição Geral:
Este script foi desenvolvido para criar um job no SQL Server Agent que automatiza a limpeza do log de erros (Error Log) do SQL Server. A limpeza é realizada executando o procedimento armazenado sp_cycle_errorlog, que fecha o log de erros atual e cria um novo arquivo vazio. O job está configurado para rodar semanalmente, todos os sábados.

### Explicação do Funcionamento
1. Job DBA - Limpa Error Log :
- Este job executa o procedimento armazenado sp_cycle_errorlog, que fecha o log de erros atual e cria um novo arquivo vazio.
- O log de erros antigo é mantido como um arquivo arquivado, permitindo consultas futuras, mas não interfere mais no desempenho do servidor.
2. Configuração do Job :
- O job está configurado para rodar semanalmente, todos os sábados, às 23:50 PM.
- Está associado à categoria Database Maintenance e notifica o operador Alerta_BD por email em caso de falha.
3. Comando sp_cycle_errorlog :
- Este comando é usado para gerenciar o tamanho do log de erros do SQL Server, evitando que ele cresça indefinidamente.
- Ele não apaga os logs antigos, apenas os arquiva, permitindo que continuem disponíveis para análise.

### Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que o operador de email Alerta_BD esteja configurado no SQL Server Agent para receber notificações de falhas.
3. O job será executado automaticamente conforme o agendamento definido (todos os sábados às 23:50 PM).
