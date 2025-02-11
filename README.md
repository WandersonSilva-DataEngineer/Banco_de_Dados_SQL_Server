# Banco_de_Dados_SQL_Server
Estrutura de Banco de Dados SQL Server com Scripts de apoio


# Pasta Administração
- Pasta com scripts de apoio para a Administração do Banco de Dados

Arquivos:

## Backup_Diferencial_DBA_JOB.sql

- Título : Rotinas de Backup Diferencial e Full para SQL Server
- Descrição : Script SQL para automatizar backups diferenciais e full no SQL Server, utilizando stored procedures e jobs no SQL Server Agent.
- Tags : SQL Server, Backup, Automatização, Stored Procedures, SQL Server Agent

Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que os diretórios de backup (F:\Backups\Diferencial\ e \\C\backup_sql\Full\) existam.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.

## Backup_Full_DBA_JOB.sql

- Título : Rotinas de Backup Full para SQL Server
- Descrição : Script SQL para automatizar backups full no SQL Server, utilizando stored procedures e jobs no SQL Server Agent.
- Tags : SQL Server, Backup, Automatização, Stored Procedures, SQL Server Agent

Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que o diretório de backup (D:\Backup\FULL\) exista.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.

## Detach_Attach_Databases_DBA_Tools.sql

- Título : Comandos para Desanexar e Anexar Bancos de Dados no SQL Server
- Descrição : Script SQL para gerar comandos de desanexação (detach) e anexação (attach) de bancos de dados no SQL Server. Útil para manutenções e movimentações de arquivos de banco de dados.
- Tags : SQL Server, Detach, Attach, Manutenção, Automatização

Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Copie os comandos gerados para desanexar ou anexar os bancos de dados conforme necessário.
3. Certifique-se de que os caminhos dos arquivos de banco de dados estão corretos antes de executar os comandos de anexação.

## Cleanup_Old_Records_DBA_Tools.sql

- Título : Limpeza Automática de Registros Antigos no SQL Server
- Descrição : Script SQL para automatizar a exclusão de registros antigos de tabelas específicas no banco de dados DBA_Tools. Útil para manter o tamanho do banco de dados sob controle.
- Tags : SQL Server, Limpeza, Manutenção, Automatização, Stored Procedures, SQL Server Agent

Instruções de Uso :
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
