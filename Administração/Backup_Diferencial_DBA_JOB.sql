-- Autor: Wanderson Silva
-- Descrição: Este script cria e gerencia rotinas de backup diferencial e full para bancos de dados no SQL Server.
-- Define o banco de dados de trabalho como DBA_Tools
USE DBA_Tools
GO

-- Criação da stored procedure para backup diferencial no disco
CREATE PROCEDURE [dbo].[stpBackup_Diferencial_Disco]
AS
    -- Declara uma tabela temporária para armazenar os nomes dos bancos de dados que serão processados
    DECLARE @Backup_Databases TABLE (Nm_database VARCHAR(500))
    
    -- Declara variáveis para armazenar o nome do banco de dados e o caminho do backup
    DECLARE @Nm_Database VARCHAR(500), @Nm_Caminho VARCHAR(5000)
    
    -- Insere na tabela temporária os nomes dos bancos de dados online, excluindo os bancos do sistema
    INSERT INTO @Backup_Databases
    SELECT Name
    FROM sys.databases
    WHERE Name NOT IN ('tempdb','msdb','master','model') AND state_desc = 'ONLINE'
    
    -- Loop para processar cada banco de dados na lista
    WHILE EXISTS (SELECT NULL FROM @Backup_Databases)
    BEGIN
        -- Seleciona o primeiro banco de dados da lista ordenada pelo nome
        SELECT TOP 1 @Nm_Database = Nm_database FROM @Backup_Databases ORDER BY Nm_database
        
        -- Define o caminho onde o backup será salvo
        SET @Nm_Caminho = 'F:\Backups\Diferencial\' + @Nm_Database + '_Diferencial_Dados.bak'
        
        -- Executa a stored procedure que realiza o backup diferencial
        EXEC DBA_Tools.dbo.stpBackup_Diferencial_Database @Nm_Caminho, @Nm_Database, @Nm_Caminho
        
        -- Remove o banco de dados processado da tabela temporária
        DELETE FROM @Backup_Databases WHERE Nm_database = @Nm_Database
    END
GO

-- Criação da stored procedure para backup diferencial de um banco específico
CREATE PROCEDURE [dbo].[stpBackup_Diferencial_Database] 
    @Caminho VARCHAR(150), -- Caminho onde o backup será salvo
    @Nm_Database VARCHAR(50), -- Nome do banco de dados
    @Ds_Backup VARCHAR(255) = NULL -- Descrição opcional do backup
AS
    -- Declara uma variável para armazenar o nome do backup
    DECLARE @Nm_Backup VARCHAR(150);
    
    -- Define o nome padrão do backup
    SET @Nm_Backup = 'Backup Diferencial em Disco ' + @Nm_Database
    
    -- Verifica se foi fornecida uma descrição para o backup
    IF (@Ds_Backup IS NULL)
    BEGIN
        -- Realiza o backup diferencial sem descrição
        BACKUP DATABASE @Nm_Database 
        TO DISK = @Caminho
        WITH FORMAT, COMPRESSION, NAME = @Caminho, DIFFERENTIAL
    END
    ELSE
    BEGIN
        -- Realiza o backup diferencial com descrição
        BACKUP DATABASE @Nm_Database 
        TO DISK = @Caminho
        WITH FORMAT, COMPRESSION, NAME = @Caminho, DESCRIPTION = @Ds_Backup, DIFFERENTIAL
    END
GO

-- Criação da stored procedure para backup full de novas databases
USE DBA_Tools
GO
CREATE PROCEDURE [dbo].[stpBackup_Novas_Databases]
AS
BEGIN
    -- Declara uma tabela temporária para armazenar os nomes dos bancos de dados criados no dia
    DECLARE @Backup_Databases TABLE (Nm_database VARCHAR(500))
    
    -- Declara variáveis para armazenar o nome do banco de dados e o caminho do backup
    DECLARE @Nm_Database VARCHAR(500), @Nm_Caminho VARCHAR(5000)
    
    -- Insere na tabela temporária os nomes dos bancos de dados criados no dia atual
    INSERT INTO @Backup_Databases
    SELECT name
    FROM sys.sysdatabases
    WHERE crdate >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
    AND name <> 'tempdb'
    AND dbid > 4
    
    -- Loop para processar cada banco de dados na lista
    WHILE EXISTS (SELECT NULL FROM @Backup_Databases)
    BEGIN
        -- Seleciona o primeiro banco de dados da lista ordenada pelo nome
        SELECT TOP 1 @Nm_Database = Nm_database FROM @Backup_Databases ORDER BY Nm_database
        
        -- Define o caminho onde o backup será salvo
        SET @Nm_Caminho = '\\C\backup_sql\Full\' + @Nm_Database + '_' 
                            + REPLACE(CONVERT(VARCHAR(10), GETDATE(), 120), '-', '') + '_Dados.bak'
        
        -- Executa a stored procedure que realiza o backup full
        EXEC DBA_Tools.dbo.stpBackup_Full_Database @Nm_Caminho, @Nm_Database, @Nm_Caminho
        
        -- Remove o banco de dados processado da tabela temporária
        DELETE FROM @Backup_Databases WHERE Nm_database = @Nm_Database
    END
END
GO

-- Criação do job no SQL Server Agent para automatizar os backups diferenciais
USE [msdb]
GO
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

-- Criação da categoria de job caso não exista
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

DECLARE @jobId BINARY(16)

-- Criação do job para backup diferencial
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N'DBA - Backup Diferencial Databases', 
    @enabled=1, -- Job habilitado
    @notify_level_eventlog=0, -- Não notifica no log de eventos
    @notify_level_email=2, -- Notifica por email em caso de falha
    @notify_level_netsend=0, -- Não notifica via net send
    @notify_level_page=0, -- Não notifica via pager
    @delete_level=0, -- Não exclui o job após execução
    @description=N'Job para backup diferencial das bases de dados.', -- Descrição do job
    @category_name=N'Database Maintenance', -- Categoria do job
    @owner_login_name=N'sa', -- Proprietário do job
    @notify_email_operator_name=N'Alerta_BD', @job_id = @jobId OUTPUT -- Operador de notificação por email
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Adiciona o primeiro passo ao job
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - Backup Diferencial Novas Databases', 
    @step_id=1, -- ID do passo
    @subsystem=N'TSQL', -- Subsistema T-SQL
    @command=N'EXEC [dbo].[stpBackup_Novas_Databases]', -- Comando a ser executado
    @database_name=N'DBA_Tools' -- Banco de dados onde o comando será executado
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Adiciona o segundo passo ao job
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'BKP Diferencial', 
    @step_id=2, -- ID do passo
    @subsystem=N'TSQL', -- Subsistema T-SQL
    @command=N'EXEC [dbo].[stpBackup_Diferencial_Disco]', -- Comando a ser executado
    @database_name=N'DBA_Tools' -- Banco de dados onde o comando será executado
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Configuração do agendamento do job
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA - Backup Diferencial Databases', 
    @enabled=1, -- Agendamento habilitado
    @freq_type=8, -- Frequência semanal
    @freq_interval=62, -- Dias da semana (segunda-feira e terça-feira)
    @freq_recurrence_factor=1, -- Recorrência semanal
    @active_start_date=20160517, -- Data de início
    @active_start_time=200000 -- Hora de início
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

EndSave:
GO