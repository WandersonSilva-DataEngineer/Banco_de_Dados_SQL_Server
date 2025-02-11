-- Autor: Wanderson Silva
-- Descrição: Este script gera comandos SQL para desanexar (detach) e anexar (attach) bancos de dados no SQL Server.
-- Define o banco de dados de trabalho como DBA_Tools
USE DBA_Tools
GO

-- Gerando comandos para desanexar (detach) todas as bases de dados, exceto os bancos de sistema
SELECT
    -- Verifica se o banco de dados está online antes de tentar desanexá-lo
    'IF EXISTS (SELECT name
                FROM sys.databases 
                WHERE State_Desc = ''ONLINE''
                AND name = ''' + A.Name + ''')
    BEGIN
        -- Altera o banco de dados para modo SINGLE_USER com rollback imediato
        ALTER DATABASE ' + A.Name + ' 
        SET SINGLE_USER WITH ROLLBACK IMMEDIATE 

        -- Executa o comando sp_detach_db para desanexar o banco de dados
        EXEC sp_detach_db ' + A.Name + '		
    END' AS Detach_Command,
    A.Name AS Database_Name
FROM sys.sysdatabases A 
WHERE A.Name NOT IN ('tempdb', 'master', 'model', 'msdb') -- Exclui os bancos de sistema

-- Gerando comandos para anexar (attach) todas as bases de dados selecionadas
SELECT 
    -- Verifica se o banco de dados não existe antes de tentar anexá-lo
    'IF NOT EXISTS (SELECT name 
                    FROM sys.databases 
                    WHERE State_Desc = ''ONLINE'' 
                    AND name = ''' + A.name + ''')
    BEGIN 
        -- Cria o banco de dados usando o comando FOR ATTACH
        CREATE DATABASE ' + A.name + '
        ON 
        (FILENAME = ''' + A.filename + '''), 
        (FILENAME = ''' + B.filename + ''') ' +
        -- Adiciona o terceiro arquivo de banco de dados, se existir
        CASE 
            WHEN C.fileid IS NULL THEN '' 
            ELSE ',(FILENAME = ''' + C.filename + ''') ' 
        END + '
        FOR ATTACH
    END' AS Attach_Command,
    A.name AS Database_Name,
    A.filename AS Primary_File_Path,
    B.name AS Logical_File_Name,
    B.filename AS Secondary_File_Path
FROM sys.sysdatabases A 
    JOIN sys.sysaltfiles B ON A.dbid = B.dbid -- Junta os arquivos principais e secundários
    LEFT JOIN sys.sysaltfiles C ON A.dbid = C.dbid AND C.fileid = 3 -- Junta o terceiro arquivo, se existir
WHERE B.fileid = 2 -- Filtra apenas os arquivos secundários (log)
    AND A.Name NOT IN ('tempdb', 'master', 'model', 'msdb') -- Exclui os bancos de sistema