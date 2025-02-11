-- Autor: Wanderson Silva
-- Descrição: Este script cria um job no SQL Server Agent para limpar o log de erros (Error Log) do SQL Server.
-- Define o banco de dados de trabalho como msdb
USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

-- Verifica se a categoria 'Database Maintenance' existe e a cria, se necessário
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
    EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
    IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

DECLARE @jobId BINARY(16)

-- Criação do job para limpar o Error Log
EXEC @ReturnCode = msdb.dbo.sp_add_job @job_name=N'DBA - Limpa Error Log', 
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
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'DBA - Limpa Error Log', 
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
    @command=N'EXEC sp_cycle_errorlog', -- Comando para limpar o Error Log
    @database_name=N'master', -- Banco de dados onde o comando será executado
    @flags=0 -- Flags adicionais
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Atualiza o job para iniciar no primeiro passo
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

-- Configuração do agendamento do job
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SEMANAL - TODO SÁBADO', 
    @enabled=1, -- Agendamento habilitado
    @freq_type=8, -- Frequência semanal
    @freq_interval=64, -- Executa aos sábados (64 = sábado)
    @freq_subday_type=1, -- Uma vez ao dia
    @freq_subday_interval=0, -- Intervalo de subdia
    @freq_relative_interval=0, -- Intervalo relativo
    @freq_recurrence_factor=1, -- Recorrência semanal
    @active_start_date=20151008, -- Data de início
    @active_end_date=99991231, -- Data de término
    @active_start_time=235000, -- Hora de início (23:50:00)
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