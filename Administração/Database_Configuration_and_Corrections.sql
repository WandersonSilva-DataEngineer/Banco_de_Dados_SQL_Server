-- Autor: Wanderson Silva
-- Descrição: Este script analisa as configurações dos bancos de dados no SQL Server e gera comandos para corrigir configurações inadequadas.

----------------------------------------------------------
-- Script Análise de Configurações de Bancos de Dados
----------------------------------------------------------
SELECT 
    database_id, -- ID do banco de dados
    CONVERT(VARCHAR(1000), DB.name) AS dbName, -- Nome do banco de dados
    state_desc AS Database_Status, -- Status do banco de dados (ONLINE, OFFLINE, etc.)
    -- Tamanho total dos arquivos de dados (em MB)
    (SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'rows') AS [Data MB],
    -- Tamanho total dos arquivos de log (em MB)
    (SELECT SUM((size*8)/1024) FROM sys.master_files WHERE DB_NAME(database_id) = DB.name AND type_desc = 'log') AS [Log MB],    
    page_verify_option_desc AS [Page Verify Option], -- Opção de verificação de página (CHECKSUM, NONE, etc.)
    recovery_model_desc AS [Recovery Model], -- Modelo de recuperação (FULL, SIMPLE, BULK_LOGGED)
    -- Último backup realizado
    ISNULL((
        SELECT TOP 1
            CASE type 
                WHEN 'D' THEN 'Full' 
                WHEN 'I' THEN 'Differential' 
                WHEN 'L' THEN 'Transaction log' 
            END + ' – ' +
            LTRIM(ISNULL(STR(ABS(DATEDIFF(DAY, GETDATE(), backup_finish_date))) + ' days ago', 'NEVER')) + ' – ' +
            CONVERT(VARCHAR(20), backup_start_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_start_date, 108) + ' – ' +
            CONVERT(VARCHAR(20), backup_finish_date, 103) + ' ' + CONVERT(VARCHAR(20), backup_finish_date, 108) +
            ' (' + CAST(DATEDIFF(second, BK.backup_start_date, BK.backup_finish_date) AS VARCHAR(4)) + ' seconds)'
        FROM msdb..backupset BK 
        WHERE BK.database_name = DB.name 
        ORDER BY backup_set_id DESC
    ), '-') AS [Last Backup],
    CASE WHEN is_auto_close_on = 1 THEN 'Auto Close Enabled' ELSE '' END AS [Auto Close], -- Verifica se AUTO_CLOSE está habilitado
    CASE WHEN is_auto_shrink_on = 1 THEN 'Auto Shrink Enabled' ELSE '' END AS [Auto Shrink], -- Verifica se AUTO_SHRINK está habilitado
    CASE WHEN is_auto_create_stats_on = 1 THEN 'Auto Create Statistics Enabled' ELSE '' END AS [Auto Create Statistics], -- Verifica se AUTO_CREATE_STATISTICS está habilitado
    CASE WHEN is_auto_update_stats_on = 1 THEN 'Auto Update Statistics Enabled' ELSE '' END AS [Auto Update Statistics], -- Verifica se AUTO_UPDATE_STATISTICS está habilitado
    CASE compatibility_level
        WHEN 60 THEN '60 (SQL Server 6.0)'
        WHEN 65 THEN '65 (SQL Server 6.5)'
        WHEN 70 THEN '70 (SQL Server 7.0)'
        WHEN 80 THEN '80 (SQL Server 2000)'
        WHEN 90 THEN '90 (SQL Server 2005)'
        WHEN 100 THEN '100 (SQL Server 2008)'
        WHEN 110 THEN '110 (SQL Server 2012)'
        WHEN 120 THEN '120 (SQL Server 2014)'
        WHEN 130 THEN '130 (SQL Server 2016)'
        WHEN 140 THEN '140 (SQL Server 2017)'
        WHEN 150 THEN '150 (SQL Server 2019)'
    END AS [Compatibility Level], -- Nível de compatibilidade do banco de dados
    user_access_desc AS [User Access], -- Tipo de acesso ao banco de dados (MULTI_USER, SINGLE_USER, etc.)
    CONVERT(VARCHAR(20), create_date, 103) + ' ' + CONVERT(VARCHAR(20), create_date, 108) AS [Creation Date], -- Data de criação do banco de dados
    CASE WHEN is_fulltext_enabled = 1 THEN 'Fulltext Enabled' ELSE '' END AS [Fulltext] -- Verifica se o suporte a Full-Text está habilitado
FROM sys.databases DB
ORDER BY [Data MB] DESC, dbName, [Last Backup] DESC, NAME;

----------------------------------------------------------
-- Script Correções de Configurações Inadequadas
----------------------------------------------------------
SELECT    
    name AS Database_Name, -- Nome do banco de dados
    -- Gera comando para alterar PAGE_VERIFY para CHECKSUM, se necessário
    CASE WHEN page_verify_option_desc <> 'CHECKSUM' THEN 'ALTER DATABASE [' + name + '] SET PAGE_VERIFY CHECKSUM;' ELSE '' END AS [Page Verify Correction],
    -- Gera comando para desabilitar AUTO_CLOSE, se necessário
    CASE WHEN is_auto_close_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CLOSE OFF;' ELSE '' END AS [Auto Close Correction],
    -- Gera comando para desabilitar AUTO_SHRINK, se necessário
    CASE WHEN is_auto_shrink_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_SHRINK OFF;' ELSE '' END AS [Auto Shrink Correction],
    -- Gera comando para habilitar AUTO_CREATE_STATISTICS, se necessário
    CASE WHEN is_auto_create_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON;' ELSE '' END AS [Auto Create Statistics Correction],
    -- Gera comando para habilitar AUTO_UPDATE_STATISTICS, se necessário
    CASE WHEN is_auto_update_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON;' ELSE '' END AS [Auto Update Statistics Correction]
FROM sys.databases DB
-- DESCOMENTAR A OPÇÃO DESEJADA PARA FILTRAR OS RESULTADOS
--WHERE
--    CASE WHEN page_verify_option_desc <> 'CHECKSUM' THEN 'ALTER DATABASE [' + name + '] SET PAGE_VERIFY CHECKSUM;' ELSE '' END <> '' -- Filtra apenas bancos com PAGE_VERIFY incorreto
--    OR CASE WHEN is_auto_close_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CLOSE OFF;' ELSE '' END <> '' -- Filtra apenas bancos com AUTO_CLOSE habilitado
--    OR CASE WHEN is_auto_shrink_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_SHRINK OFF;' ELSE '' END <> '' -- Filtra apenas bancos com AUTO_SHRINK habilitado
--    OR CASE WHEN is_auto_create_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON;' ELSE '' END <> '' -- Filtra apenas bancos sem AUTO_CREATE_STATISTICS
--    OR CASE WHEN is_auto_update_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON;' ELSE '' END <> '' -- Filtra apenas bancos sem AUTO_UPDATE_STATISTICS
ORDER BY name;

/*
----------------------------------------------------------
-- Script para Testes
----------------------------------------------------------
-- Criação de bancos de dados para testar as correções
CREATE DATABASE TESTE_TODOS;
ALTER DATABASE TESTE_TODOS SET PAGE_VERIFY NONE;
ALTER DATABASE TESTE_TODOS SET AUTO_CLOSE ON;
ALTER DATABASE TESTE_TODOS SET AUTO_SHRINK ON;
ALTER DATABASE TESTE_TODOS SET AUTO_CREATE_STATISTICS OFF;
ALTER DATABASE TESTE_TODOS SET AUTO_UPDATE_STATISTICS OFF;

CREATE DATABASE TESTE_PAGEVERIFY;
ALTER DATABASE TESTE_PAGEVERIFY SET PAGE_VERIFY NONE;

CREATE DATABASE TESTE_AUTOCLOSE;
ALTER DATABASE TESTE_AUTOCLOSE SET AUTO_CLOSE ON;

CREATE DATABASE TESTE_AUTOSHRINK;
ALTER DATABASE TESTE_AUTOSHRINK SET AUTO_SHRINK ON;

CREATE DATABASE TESTE_STATISTICS;
ALTER DATABASE TESTE_STATISTICS SET AUTO_CREATE_STATISTICS OFF;
ALTER DATABASE TESTE_STATISTICS SET AUTO_UPDATE_STATISTICS OFF;

CREATE DATABASE TESTE_BACKUP;
BACKUP DATABASE TESTE_BACKUP
TO DISK = 'C:\SQLServer\Backup\TESTE_BACKUP_Dados.bak'; -- Altere para um caminho válido

-- Exclusão dos bancos de dados de teste
DROP DATABASE TESTE_TODOS;
DROP DATABASE TESTE_PAGEVERIFY;
DROP DATABASE TESTE_AUTOCLOSE;
DROP DATABASE TESTE_AUTOSHRINK;
DROP DATABASE TESTE_STATISTICS;
DROP DATABASE TESTE_BACKUP;
*/