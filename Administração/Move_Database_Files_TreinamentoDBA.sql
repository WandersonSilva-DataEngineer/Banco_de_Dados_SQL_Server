-- Autor: Wanderson Silva
-- Descrição: Este script move os arquivos de dados e log da base de dados TreinamentoDBA para um novo local no servidor.
-- Define o banco de dados de trabalho como master
USE master
GO

--------------------------------------------------------------------------------------------------------------------------------
-- 1. Encerramento de Conexões Ativas na Base de Dados
--------------------------------------------------------------------------------------------------------------------------------
-- Para deixar uma base offline é necessário matar todas as conexões que estão utilizando essa base de dados.
DECLARE @SpId AS VARCHAR(5); -- Variável para armazenar o ID do processo (SPID)

-- Verifica se a tabela temporária #Processos existe e a exclui, se necessário
IF OBJECT_ID('tempdb..#Processos') IS NOT NULL 
    DROP TABLE #Processos;

-- Cria uma tabela temporária para armazenar os IDs das conexões ativas na base TreinamentoDBA
SELECT CAST(spid AS VARCHAR(5)) AS SpId
INTO #Processos
FROM master.dbo.sysprocesses A
JOIN master.dbo.sysdatabases B ON A.DbId = B.DbId
WHERE B.Name = 'TreinamentoDBA';

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

--------------------------------------------------------------------------------------------------------------------------------
-- 2. Alteração do Status da Base de Dados para OFFLINE
--------------------------------------------------------------------------------------------------------------------------------
-- Altera o status da base de dados TreinamentoDBA para OFFLINE
ALTER DATABASE TreinamentoDBA SET OFFLINE;

--------------------------------------------------------------------------------------------------------------------------------
-- 3. Movimentação dos Arquivos de Dados e Log
--------------------------------------------------------------------------------------------------------------------------------
-- Busca o nome lógico e o caminho físico dos arquivos de dados e log associados à base de dados TreinamentoDBA
SELECT 
    name AS Logical_Name, -- Nome lógico do arquivo
    physical_name AS Physical_Path -- Caminho físico do arquivo
FROM sys.master_files 
WHERE database_id = DB_ID('TreinamentoDBA');

-- Altera o caminho do arquivo de dados (*.mdf)
ALTER DATABASE TreinamentoDBA MODIFY FILE (
    NAME = TreinamentoDBA, -- Nome lógico do arquivo de dados
    FILENAME = 'C:\TEMP\TreinamentoDBA.mdf' -- Novo caminho físico
);

-- Altera o caminho do arquivo de log (*.ldf)
ALTER DATABASE TreinamentoDBA MODIFY FILE (
    NAME = TreinamentoDBA_log, -- Nome lógico do arquivo de log
    FILENAME = 'C:\TEMP\TreinamentoDBA_log.ldf' -- Novo caminho físico
);

-- IMPORTANTE: Certifique-se de que os arquivos foram movidos manualmente para o novo caminho antes de executar esta etapa.
-- Garantir que o usuário do SQL Server tem acesso aos arquivos de dados e logs na nova pasta.

--------------------------------------------------------------------------------------------------------------------------------
-- 4. Alteração do Status da Base de Dados para ONLINE
--------------------------------------------------------------------------------------------------------------------------------
-- Altera o status da base de dados TreinamentoDBA para ONLINE
ALTER DATABASE TreinamentoDBA SET ONLINE;

--------------------------------------------------------------------------------------------------------------------------------
-- 5. Verificação Final
--------------------------------------------------------------------------------------------------------------------------------
-- Verifica o novo local dos arquivos de dados e log
SELECT 
    name AS Logical_Name, -- Nome lógico do arquivo
    physical_name AS Physical_Path -- Caminho físico do arquivo
FROM sys.master_files 
WHERE database_id = DB_ID('TreinamentoDBA');

-- Executa uma verificação de integridade da base de dados
DBCC CHECKDB('TreinamentoDBA');