<?php

declare(strict_types=1);

require __DIR__ . '/lib/mcp_client.php';

function usage(): void
{
    $usage = <<<'TXT'
Usage:
  php mcp-tool.php --list-tools [--config path]
  php mcp-tool.php --tool <name> [--args-json '{...}' | --args-file path] [--config path]

Calls one PhpStorm MCP tool through the configurable Streamable HTTP endpoint.
TXT;
    fwrite(STDERR, $usage . PHP_EOL);
    exit(1);
}

$options = getopt('', ['config:', 'list-tools', 'tool:', 'args-json:', 'args-file:']);
if (! is_array($options)) {
    usage();
}

try {
    $client = new SkillMcpClient(SkillMcpClient::loadConfig($options['config'] ?? null));

    if (array_key_exists('list-tools', $options)) {
        echo json_encode(['tools' => $client->listTools()], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;
        exit(0);
    }

    $tool = $options['tool'] ?? null;
    if (! is_string($tool) || $tool === '') {
        usage();
    }

    $args = [];
    if (isset($options['args-json'])) {
        $decoded = json_decode((string) $options['args-json'], true);
        if (! is_array($decoded)) {
            throw new RuntimeException('Invalid --args-json payload.');
        }
        $args = $decoded;
    } elseif (isset($options['args-file'])) {
        $contents = file_get_contents((string) $options['args-file']);
        if ($contents === false) {
            throw new RuntimeException(sprintf('Unable to read args file: %s', (string) $options['args-file']));
        }
        $decoded = json_decode($contents, true);
        if (! is_array($decoded)) {
            throw new RuntimeException('Invalid --args-file JSON payload.');
        }
        $args = $decoded;
    }

    echo json_encode($client->callTool($tool, $args), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES) . PHP_EOL;
} catch (Throwable $e) {
    fwrite(STDERR, $e->getMessage() . PHP_EOL);
    exit(1);
}
