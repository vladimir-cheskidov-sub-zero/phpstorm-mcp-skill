<?php

declare(strict_types=1);

require __DIR__ . '/lib/mcp_client.php';

function usage(): void
{
    $usage = <<<'TXT'
Usage:
  php phpstorm-project-bootstrap.php --project-path <path> [--config path] [--composer-filter '*']

Runs the standard PhpStorm MCP PHP project bootstrap in one MCP session.
TXT;
    fwrite(STDERR, $usage . PHP_EOL);
    exit(1);
}

$options = getopt('', ['project-path:', 'config:', 'composer-filter:']);
if (! is_array($options) || empty($options['project-path'])) {
    usage();
}

$projectPath = (string) $options['project-path'];
$composerFilter = isset($options['composer-filter']) ? (string) $options['composer-filter'] : '*';

try {
    $client = new SkillMcpClient(SkillMcpClient::loadConfig($options['config'] ?? null));
    $result = [
        'projectPath' => $projectPath,
        'phpProjectConfig' => $client->callTool('get_php_project_config', ['projectPath' => $projectPath])['structuredContent'] ?? null,
        'composerDependencies' => $client->callTool('get_composer_dependencies', ['projectPath' => $projectPath, 'nameFilter' => $composerFilter])['structuredContent'] ?? null,
        'projectModules' => $client->callTool('get_project_modules', ['projectPath' => $projectPath])['structuredContent'] ?? null,
        'repositories' => $client->callTool('get_repositories', ['projectPath' => $projectPath])['structuredContent'] ?? null,
        'runConfigurations' => $client->callTool('get_run_configurations', ['projectPath' => $projectPath])['structuredContent'] ?? null,
    ];

    echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;
} catch (Throwable $e) {
    fwrite(STDERR, $e->getMessage() . PHP_EOL);
    exit(1);
}
