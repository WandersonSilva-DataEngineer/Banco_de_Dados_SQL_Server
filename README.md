# Banco_de_Dados_SQL_Server
Estrutura de Banco de Dados SQL Server com Scripts de apoio


# Pasta Administração
- Pasta com scripts de apoio para a Administração do Banco de Dados

Arquivos:

## Backup_Diferencial_DBA_JOB.sql

Título : Rotinas de Backup Diferencial e Full para SQL Server
Descrição : Script SQL para automatizar backups diferenciais e full no SQL Server, utilizando stored procedures e jobs no SQL Server Agent.
Tags : SQL Server, Backup, Automatização, Stored Procedures, SQL Server Agent

Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que os diretórios de backup (F:\Backups\Diferencial\ e \\C\backup_sql\Full\) existam.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.

## Backup_Full_DBA_JOB.sql

Uso no GitHub
Este script pode ser documentado no GitHub com as seguintes informações:

Título : Rotinas de Backup Full para SQL Server
Descrição : Script SQL para automatizar backups full no SQL Server, utilizando stored procedures e jobs no SQL Server Agent.
Tags : SQL Server, Backup, Automatização, Stored Procedures, SQL Server Agent

Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que o diretório de backup (D:\Backup\FULL\) exista.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.

## Detach_Attach_Databases_DBA_Tools.sql

Este script pode ser documentado no GitHub com as seguintes informações:

Título : Comandos para Desanexar e Anexar Bancos de Dados no SQL Server
Descrição : Script SQL para gerar comandos de desanexação (detach) e anexação (attach) de bancos de dados no SQL Server. Útil para manutenções e movimentações de arquivos de banco de dados.
Tags : SQL Server, Detach, Attach, Manutenção, Automatização

Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Copie os comandos gerados para desanexar ou anexar os bancos de dados conforme necessário.
3. Certifique-se de que os caminhos dos arquivos de banco de dados estão corretos antes de executar os comandos de anexação.

## Cleanup_Old_Records_DBA_Tools.sql

Este script pode ser documentado no GitHub com as seguintes informações:

Título : Limpeza Automática de Registros Antigos no SQL Server
Descrição : Script SQL para automatizar a exclusão de registros antigos de tabelas específicas no banco de dados DBA_Tools. Útil para manter o tamanho do banco de dados sob controle.
Tags : SQL Server, Limpeza, Manutenção, Automatização, Stored Procedures, SQL Server Agent

Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que as tabelas mencionadas no script existam no banco de dados DBA_Tools.
3. Configure o operador de email Alerta_BD no SQL Server Agent para receber notificações de falhas.