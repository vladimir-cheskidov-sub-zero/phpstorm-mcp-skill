<?php

declare(strict_types=1);

require __DIR__ . '/lib/SkillMcpClient.php';

function usage(): void
{
    $usage = <<<'TXT'
Usage:
  php phpstorm-batch-inspections.php --project-path <path> --files-json <path> [--config path] [--min-severity WEAK_WARNING]

Runs get_inspections for a JSON array of project-relative file paths in one MCP session.
TXT;
    fwrite(STDERR, $usage . PHP_EOL);
    exit(1);
}

$options = getopt('', ['project-path:', 'files-json:', 'config:', 'min-severity:']);
if (! is_array($options) || empty($options['project-path']) || empty($options['files-json'])) {
    usage();
}

$filesJson = file_get_contents((string) $options['files-json']);
if ($filesJson === false) {
    fwrite(STDERR, 'Unable to read --files-json.' . PHP_EOL);
    exit(1);
}

$files = json_decode($filesJson, true);
if (! is_array($files)) {
    fwrite(STDERR, '--files-json must contain a JSON array.' . PHP_EOL);
    exit(1);
}

$projectPath = (string) $options['project-path'];
$minSeverity = (string) ($options['min-severity'] ?? 'WEAK_WARNING');

try {
    $client = new SkillMcpClient(SkillMcpClient::loadConfig($options['config'] ?? null));
    $result = [
        'projectPath' => $projectPath,
        'minSeverity' => $minSeverity,
        'files' => [],
    ];

    foreach ($files as $file) {
        if (! is_string($file) || $file === '') {
            continue;
        }

        $result['files'][$file] = $client->callTool('get_inspections', [
            'projectPath' => $projectPath,
            'filePath' => $file,
            'minSeverity' => $minSeverity,
        ])['structuredContent'] ?? null;
    }

    echo json_encode($result, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;
} catch (Throwable $e) {
    fwrite(STDERR, $e->getMessage() . PHP_EOL);
    exit(1);
}
