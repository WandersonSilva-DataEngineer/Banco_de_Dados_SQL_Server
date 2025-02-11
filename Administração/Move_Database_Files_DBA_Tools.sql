-- Autor: Wanderson Silva
-- Descrição: Este script move os arquivos de dados e log de uma base de dados (TESTE_LUIZ) para um novo local no servidor.
-- Define o banco de dados de trabalho como master
USE master
GO

-- 1. Busca o nome lógico e o caminho físico dos arquivos de dados e log associados à base de dados TESTE_LUIZ
SELECT 
    name AS Logical_Name, -- Nome lógico do arquivo
    physical_name AS Physical_Path -- Caminho físico do arquivo
FROM sys.master_files 
WHERE database_id = DB_ID('TESTE_LUIZ');

-- Verifica o status atual da base de dados TESTE_LUIZ
SELECT 
    name AS Database_Name, -- Nome da base de dados
    state_desc AS Status_Description -- Estado atual da base de dados
FROM sys.databases
WHERE name = 'TESTE_LUIZ';

-- 2. Verifica se existem conexões ativas na base de dados TESTE_LUIZ e as encerra
DECLARE @SpId AS VARCHAR(5); -- Variável para armazenar o ID do processo (SPID)

-- Cria uma tabela temporária para armazenar os IDs das conexões ativas
IF OBJECT_ID('tempdb..#Processos') IS NOT NULL 
    DROP TABLE #Processos;

-- Insere os IDs das conexões ativas na tabela temporária
SELECT CAST(spid AS VARCHAR(5)) AS SpId
INTO #Processos
FROM master.dbo.sysprocesses A
JOIN master.dbo.sysdatabases B ON A.DbId = B.DbId
WHERE B.Name = 'TESTE_LUIZ';

-- Loop para encerrar todas as conexões ativas
WHILE (SELECT COUNT(*) FROM #Processos) > 0
BEGIN
    -- Seleciona o primeiro SPID da lista
    SET @SpId = (SELECT TOP 1 SpID FROM #Processos);
    
    -- Encerra a conexão usando o comando KILL
    EXEC ('KILL ' + @SpId);
    
    -- Remove o SPID processado da tabela temporária
    DELETE FROM #Processos WHERE SpID = @SpId;
END;

-- 3. Altera o status da base de dados TESTE_LUIZ para OFFLINE
ALTER DATABASE TESTE_LUIZ SET OFFLINE;

-- 4. Altera os caminhos físicos dos arquivos de dados e log para o novo local
-- Altera o caminho do arquivo de dados (*.mdf)
ALTER DATABASE TESTE_LUIZ MODIFY FILE (
    NAME = TESTE_LUIZ, -- Nome lógico do arquivo de dados
    FILENAME = 'C:\Luiz Vitor\Novo Caminho\TESTE_LUIZ.mdf' -- Novo caminho físico
);

-- Altera o caminho do arquivo de log (*.ldf)
ALTER DATABASE TESTE_LUIZ MODIFY FILE (
    NAME = TESTE_LUIZ_log, -- Nome lógico do arquivo de log
    FILENAME = 'C:\Luiz Vitor\Novo Caminho\TESTE_LUIZ_log.ldf' -- Novo caminho físico
);

-- 5. Altera o status da base de dados TESTE_LUIZ para ONLINE
ALTER DATABASE TESTE_LUIZ SET ONLINE;

-- Conferindo o resultado após a alteração
-- Local dos arquivos
SELECT 
    name AS Logical_Name, -- Nome lógico do arquivo
    physical_name AS Physical_Path -- Caminho físico do arquivo
FROM sys.master_files 
WHERE database_id = DB_ID('TESTE_LUIZ');

-- Verifica o status da base de dados TESTE_LUIZ
SELECT 
    name AS Database_Name, -- Nome da base de dados
    state_desc AS Status_Description -- Estado atual da base de dados
FROM sys.databases
WHERE name = 'TESTE_LUIZ';