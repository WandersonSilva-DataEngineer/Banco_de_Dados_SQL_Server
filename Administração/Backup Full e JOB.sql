-- Autor: Wanderson Silva
-- Descrição: Este script cria e gerencia rotinas de backup full para bancos de dados no SQL Server.
-- Define o banco de dados de trabalho como DBA_Tools
USE DBA_Tools
GO

/*
ALTERAR O caminho do backup para o tamanho escolhido pelo cliente: D:\Backup\FULL\
 -- COMPRESSION  --incluir a compressão caso a versão seja maior que a 2008 R2
*/

-- Verifica se a stored procedure 'stpBackup_FULL_Database' já existe e a exclui, se necessário
IF OBJECT_ID('stpBackup_FULL_Database') IS NOT NULL
    DROP PROCEDURE stpBackup_FULL_Database
         
GO

-- Criação da stored procedure para backup full de um banco específico
CREATE PROCEDURE [dbo].[stpBackup_FULL_Database] 
    @Caminho VARCHAR(150), -- Caminho onde o backup será salvo
    @Nm_Database VARCHAR(500), -- Nome do banco de dados
    @Ds_Backup VARCHAR(255) = NULL -- Descrição opcional do backup (255 é o maior valor aceito pelo campo description da tabela 'msdb.dbo.backupset')
AS
BEGIN
    -- Declara uma variável para armazenar o nome do backup
    DECLARE @Nm_Backup VARCHAR(150);
    
    -- Define o nome padrão do backup
    SET @Nm_Backup = 'Backup FULL em Disco ' + @Nm_Database
    
    -- Verifica se foi fornecida uma descrição para o backup
    IF (@Ds_Backup IS NULL)
    BEGIN
        -- Realiza o backup full sem descrição
        BACKUP DATABASE @Nm_Database 
        TO DISK = @Caminho
        WITH FORMAT, CHECKSUM, NAME = @Nm_Backup, COMPRESSION
    END
    ELSE
    BEGIN
        -- Realiza o backup full com descrição
        BACKUP DATABASE @Nm_Database 
        TO DISK = @Caminho
        WITH FORMAT, CHECKSUM, NAME = @Caminho, DESCRIPTION = @Ds_Backup, COMPRESSION
    END
END
GO

-- Verifica se a stored procedure 'stpBackup_Databases_Disco' já existe e a exclui, se necessário
IF OBJECT_ID('stpBackup_Databases_Disco') IS NOT NULL
    DROP PROCEDURE stpBackup_Databases_Disco
GO

-- Criação da stored procedure para backup full de todos os bancos de dados online
CREATE PROCEDURE [dbo].[stpBackup_Databases_Disco]
AS
BEGIN
    -- Declara uma tabela temporária para armazenar os nomes dos bancos de dados que serão processados
    DECLARE @Backup_Databases TABLE (Nm_database VARCHAR(500))
    
    -- Declara variáveis para armazenar o nome do banco de dados e o caminho do backup
    DECLARE @Nm_Database VARCHAR(500), @Nm_Caminho VARCHAR(5000)
    
    -- Insere na tabela temporária os nomes dos bancos de dados online, excluindo o banco tempdb
    INSERT INTO @Backup_Databases
    SELECT name
    FROM sys.databases
    WHERE 
        name NOT IN ('tempdb') 
        AND state_desc = 'ONLINE'
    
    -- Exclui as bases que devem ser desconsideradas (comentado para uso futuro)
    -- DELETE FROM @Backup_Databases
    -- WHERE Nm_database IN (SELECT Nm_Database FROM [dbo].[Desconsiderar_Databases_Rotinas])
    
    /*
    -- BACKUP FULL DAS BASES ABAIXO SOMENTE NO DOMINGO
    IF((SELECT DATEPART(WEEKDAY, GETDATE())) <> 1 )
    BEGIN
        DELETE FROM @Backup_Databases
        WHERE Nm_database IN ('JF','NFEJF')
    END
    */
    
    -- Loop para processar cada banco de dados na lista
    WHILE EXISTS (SELECT NULL FROM @Backup_Databases)
    BEGIN
        -- Seleciona o primeiro banco de dados da lista ordenada pelo nome
        SELECT TOP 1 @Nm_Database = Nm_database FROM @Backup_Databases ORDER BY Nm_database
        
        -- Define o caminho onde o backup será salvo
        /*
        -- Armazena uma semana de backup
        SET @Nm_Caminho = 'D:\BKP_DADOS\Full\' + @Nm_Database + '_' + 
                          (CASE DATEPART(WEEKDAY, GETDATE()) 
                              WHEN 1 THEN 'Domingo'
                              WHEN 2 THEN 'Segunda'
                              WHEN 3 THEN 'Terca'
                              WHEN 4 THEN 'Quarta'
                              WHEN 5 THEN 'Quinta' 
                              WHEN 6 THEN 'Sexta'
                              WHEN 7 THEN 'Sabado'
                           END) + '_Dados.bak'
        */
        SET @Nm_Caminho = 'D:\Backup\FULL\' + @Nm_Database + '_Dados.bak'
        
        -- Executa a stored procedure que realiza o backup full
        EXEC DBA_Tools.dbo.stpBackup_FULL_Database @Nm_Caminho, @Nm_Database, @Nm_Caminho
        
        -- Remove o banco de dados processado da tabela temporária
        DELETE FROM @Backup_Databases WHERE Nm_database = @Nm_Database
    END
END
GO

-- Configuração do job no SQL Server Agent para automatizar os backups full
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

-- Criação do job para backup full
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N'DBA - Backup Databases FULL', 
    @enabled=1, -- Job habilitado
    @notify_level_eventlog=0, -- Não notifica no log de eventos
    @notify_level_email=2, -- Notifica por email em caso de falha
    @notify_level_netsend=0, -- Não notifica via net send
    @notify_level_page=0, -- Não notifica via pager
    @delete_level=0, -- Não exclui o job após execução
    @description=N'No description available.', -- Descrição do job
    @category_name=N'Database Maintenance', -- Categoria do job
    @owner_login_name=N'sa', -- Proprietário do job
    @notify_email_operator_name=N'Alerta_BD', -- Operador de notificação por email
    @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Adiciona o passo ao job
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - Backup Databases FULL', 
    @step_id=1, -- ID do passo
    @cmdexec_success_code=0, -- Código de sucesso da execução
    @on_success_action=1, -- Ação em caso de sucesso (finaliza o job)
    @on_success_step_id=0, -- Passo seguinte em caso de sucesso
    @on_fail_action=2, -- Ação em caso de falha (encerra o job com erro)
    @on_fail_step_id=0, -- Passo seguinte em caso de falha
    @retry_attempts=0, -- Número de tentativas de reexecução
    @retry_interval=0, -- Intervalo entre tentativas
    @os_run_priority=0, -- Prioridade de execução no sistema operacional
    @subsystem=N'TSQL', -- Subsistema T-SQL
    @command=N'EXEC stpBackup_Databases_Disco', -- Comando a ser executado
    @database_name=N'DBA_Tools', -- Banco de dados onde o comando será executado
    @flags=0 -- Flags adicionais
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Atualiza o job para iniciar no primeiro passo
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Configuração do agendamento do job
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DBA - Backup Databases FULL', 
    @enabled=1, -- Agendamento habilitado
    @freq_type=4, -- Frequência diária
    @freq_interval=1, -- Todos os dias
    @freq_subday_type=1, -- Uma vez ao dia
    @freq_subday_interval=0, -- Intervalo de subdia
    @freq_relative_interval=0, -- Intervalo relativo
    @freq_recurrence_factor=0, -- Fator de recorrência
    @active_start_date=20140427, -- Data de início
    @active_end_date=99991231, -- Data de término
    @active_start_time=10000, -- Hora de início (10:00:00)
    @active_end_time=235959 -- Hora de término (23:59:59)
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Adiciona o job ao servidor local
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION

EndSave:
GO