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

## Move_Database_Files_DBA_Tools.sql

- Descrição Geral: Este script foi desenvolvido para mover os arquivos de dados e log de uma base de dados específica (TESTE_LUIZ) para um novo local no servidor. Ele inclui etapas para verificar o status da base, encerrar conexões ativas, alterar o estado da base para offline, modificar os caminhos dos arquivos e, finalmente, trazer a base de volta para online.

### Explicação do Funcionamento
1. Etapa 1: Verificação Inicial :
- O script começa verificando o nome lógico e o caminho físico dos arquivos de dados e log associados à base de dados TESTE_LUIZ.
- Também verifica o status atual da base de dados para garantir que ela esteja online antes de iniciar o processo.
2. Etapa 2: Encerramento de Conexões Ativas :
- Identifica todas as conexões ativas na base de dados TESTE_LUIZ e as encerra usando o comando KILL.
- Isso é necessário para evitar conflitos ao alterar o estado da base para offline.
3. Etapa 3: Alteração para Offline :
- Altera o estado da base de dados para OFFLINE, permitindo que os arquivos possam ser movidos fisicamente para o novo local.
4. Etapa 4: Alteração dos Caminhos dos Arquivos :
- Atualiza os caminhos físicos dos arquivos de dados (*.mdf) e log (*.ldf) para o novo local especificado.
- É importante mover os arquivos manualmente para o novo caminho antes de executar esta etapa.
5. Etapa 5: Alteração para Online :
- Altera o estado da base de dados de volta para ONLINE, permitindo que ela seja acessada novamente.
6. Conferência Final :
- Após a conclusão do processo, o script verifica novamente os caminhos físicos dos arquivos e o status da base de dados para confirmar que tudo foi configurado corretamente.

### Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Certifique-se de que os arquivos de dados e log foram movidos manualmente para o novo caminho antes de executar a etapa de modificação dos caminhos.
3. Substitua os nomes lógicos e caminhos físicos conforme necessário para sua base de dados.

## Move_Database_Files_TreinamentoDBA.sql

- Descrição Geral: Este script foi desenvolvido para mover os arquivos de dados (*.mdf) e log (*.ldf) da base de dados TreinamentoDBA para um novo local no servidor. Ele inclui etapas para encerrar conexões ativas, alterar o estado da base para offline, modificar os caminhos dos arquivos e trazer a base de volta para online. Além disso, realiza verificações para garantir que a operação foi concluída com sucesso.

### Explicação do Funcionamento
1. Encerramento de Conexões Ativas :
- O script identifica todas as conexões ativas na base de dados TreinamentoDBA e as encerra usando o comando KILL.
- Isso é necessário porque uma base de dados não pode ser colocada offline enquanto houver conexões ativas.
2. Alteração para Offline :
- A base de dados é colocada em modo OFFLINE, permitindo que os arquivos possam ser movidos fisicamente para o novo local.
3. Movimentação dos Arquivos :
- Os caminhos físicos dos arquivos de dados (*.mdf) e log (*.ldf) são atualizados para o novo local especificado.
- É importante mover os arquivos manualmente para o novo caminho antes de executar esta etapa.
- Certifique-se de que o usuário do SQL Server tenha permissões adequadas para acessar os arquivos no novo local.
4. Alteração para Online :
- A base de dados é colocada de volta em modo ONLINE, permitindo que ela seja acessada novamente.
5. Verificação Final :
- Após a conclusão do processo, o script verifica os novos caminhos físicos dos arquivos e executa uma verificação de integridade (DBCC CHECKDB) para garantir que a base de dados está íntegra.

## Database_Configuration_and_Corrections.sql

- Descrição Geral: Este script foi desenvolvido para analisar e corrigir configurações de bancos de dados no SQL Server. Ele inclui duas partes principais:

1. Análise de Configurações : Exibe informações detalhadas sobre os bancos de dados, como tamanho dos arquivos, modelo de recuperação, último backup, e configurações específicas.
2. Correções Automatizadas : Gera comandos SQL para ajustar configurações inadequadas, como PAGE_VERIFY, AUTO_CLOSE, AUTO_SHRINK, e estatísticas automáticas.

### Explicação do Funcionamento
1. Análise de Configurações :
- O primeiro bloco de código exibe informações detalhadas sobre todos os bancos de dados no servidor, incluindo:
-- Tamanho dos arquivos de dados e log.
-- Modelo de recuperação.
-- Último backup realizado.
-- Configurações como AUTO_CLOSE, AUTO_SHRINK, e estatísticas automáticas.
-- Nível de compatibilidade e data de criação.
- Essas informações são úteis para identificar problemas ou configurações inadequadas.
2. Correções Automatizadas :
- O segundo bloco de código gera comandos SQL para corrigir configurações inadequadas, como:
-- Alterar PAGE_VERIFY para CHECKSUM.
-- Desabilitar AUTO_CLOSE e AUTO_SHRINK.
-- Habilitar AUTO_CREATE_STATISTICS e AUTO_UPDATE_STATISTICS.
- Os comandos gerados podem ser copiados e executados diretamente para aplicar as correções.
3. Script para Testes :
- O terceiro bloco de código (comentado) permite criar bancos de dados de teste com configurações inadequadas para validar o funcionamento do script.
- Após os testes, os bancos de dados criados são excluídos.

### Instruções de Uso :
1. Execute o script em um servidor SQL Server com permissões administrativas.
2. Revise as informações exibidas na primeira parte do script para identificar configurações inadequadas.
3. Copie e execute os comandos gerados na segunda parte do script para aplicar as correções necessárias.
4. Utilize o script de teste (bloco comentado) para validar o funcionamento do script em um ambiente de desenvolvimento.