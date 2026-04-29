<?php

declare(strict_types=1);

/**
 * Minimal Streamable HTTP MCP client for skill automation scripts.
 * Compatible with PHP 7.4 and intentionally dependency-free.
 */
final class SkillMcpClient
{
    /** @var array<string, mixed> */
    private array $config;

    private ?string $sessionId = null;

    private int $nextId = 1;

    /**
     * @param array<string, mixed> $config
     */
    public function __construct(array $config)
    {
        $this->config = $config;
    }

    /**
     * @return array<string, mixed>
     */
    public static function loadConfig(?string $configPath = null, string $server = 'phpstorm'): array
    {
        $isDefaultPath = $configPath === null;
        if ($configPath === null) {
            $configPath = dirname(__DIR__, 2) . DIRECTORY_SEPARATOR . 'config' . DIRECTORY_SEPARATOR . 'mcp.php';
        }

        if (! is_file($configPath)) {
            $message = sprintf('MCP config file not found: %s', $configPath);
            if ($isDefaultPath) {
                $message .= sprintf(
                    '. Create it with: %s <mcp-url>',
                    dirname(__DIR__) . DIRECTORY_SEPARATOR . 'configure-mcp.sh'
                );
            }

            throw new RuntimeException($message);
        }

        $config = require $configPath;
        if (! is_array($config) || ! isset($config[$server]) || ! is_array($config[$server])) {
            throw new RuntimeException(sprintf('MCP config file does not contain server "%s".', $server));
        }

        $serverConfig = $config[$server];
        foreach ($serverConfig as $key => $value) {
            if (is_string($value) && self::containsPlaceholder($value)) {
                throw new RuntimeException(sprintf(
                    'MCP config contains unresolved placeholder for "%s". Run %s <mcp-url> to create a concrete config.',
                    (string) $key,
                    dirname(__DIR__) . DIRECTORY_SEPARATOR . 'configure-mcp.sh'
                ));
            }
        }

        if (empty($serverConfig['enabled'])) {
            throw new RuntimeException(sprintf('MCP server "%s" is disabled in config.', $server));
        }

        return $serverConfig;
    }

    public function initialize(): void
    {
        if ($this->sessionId !== null) {
            return;
        }

        $response = $this->request('initialize', [
            'protocolVersion' => (string) ($this->config['protocolVersion'] ?? '2025-03-26'),
            'capabilities' => new stdClass(),
            'clientInfo' => [
                'name' => (string) ($this->config['clientName'] ?? 'codex-skill-script'),
                'version' => (string) ($this->config['clientVersion'] ?? '0.1.0'),
            ],
        ], true);

        if (($response['sessionId'] ?? null) === null) {
            throw new RuntimeException('MCP initialize response did not include mcp-session-id header.');
        }

        $this->sessionId = (string) $response['sessionId'];
        $this->notify('notifications/initialized', []);
    }

    /**
     * @return array<string, mixed>
     */
    public function listTools(): array
    {
        $this->initialize();
        $response = $this->request('tools/list', []);

        return $response['json']['result']['tools'] ?? [];
    }

    /**
     * @param array<string, mixed> $arguments
     * @return array<string, mixed>
     */
    public function callTool(string $name, array $arguments = []): array
    {
        $this->initialize();
        $response = $this->request('tools/call', [
            'name' => $name,
            'arguments' => (object) $arguments,
        ]);

        return $response['json']['result'] ?? [];
    }

    /**
     * @param array<string, mixed> $params
     */
    public function notify(string $method, array $params): void
    {
        $this->post([
            'jsonrpc' => '2.0',
            'method' => $method,
            'params' => (object) $params,
        ]);
    }

    /**
     * @param array<string, mixed> $params
     * @return array<string, mixed>
     */
    private function request(string $method, array $params, bool $isInitialize = false): array
    {
        $payload = [
            'jsonrpc' => '2.0',
            'id' => $this->nextId++,
            'method' => $method,
            'params' => (object) $params,
        ];

        $response = $this->post($payload);
        $json = $response['json'];
        if (isset($json['error'])) {
            throw new RuntimeException(sprintf('MCP request %s failed: %s', $method, json_encode($json['error'], JSON_UNESCAPED_SLASHES)));
        }

        if ($isInitialize) {
            return $response;
        }

        return $response;
    }

    /**
     * @param array<string, mixed> $payload
     * @return array<string, mixed>
     */
    private function post(array $payload): array
    {
        $url = (string) ($this->config['url'] ?? '');
        if ($url === '') {
            throw new RuntimeException('MCP config url is empty.');
        }

        $headers = [
            'Content-Type: application/json',
            'Accept: application/json, text/event-stream',
        ];

        if ($this->sessionId !== null) {
            $headers[] = 'mcp-session-id: ' . $this->sessionId;
        }

        $body = json_encode($payload, JSON_UNESCAPED_SLASHES);
        if ($body === false) {
            throw new RuntimeException('Unable to encode MCP payload.');
        }

        $httpHeaders = '';
        $ch = curl_init($url);
        if ($ch === false) {
            throw new RuntimeException('Unable to initialize curl.');
        }

        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $body);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, (int) ($this->config['timeoutSeconds'] ?? 30));
        curl_setopt($ch, CURLOPT_HEADERFUNCTION, static function ($curl, string $header) use (&$httpHeaders): int {
            $httpHeaders .= $header;

            return strlen($header);
        });

        $raw = curl_exec($ch);
        if ($raw === false) {
            $error = curl_error($ch);
            curl_close($ch);
            throw new RuntimeException(sprintf('MCP curl request failed: %s', $error));
        }

        $status = (int) curl_getinfo($ch, CURLINFO_RESPONSE_CODE);
        curl_close($ch);

        $sessionId = self::extractHeader($httpHeaders, 'mcp-session-id');
        $json = self::decodeJsonOrSse((string) $raw);

        if ($status >= 400) {
            throw new RuntimeException(sprintf('MCP HTTP %d: %s', $status, (string) $raw));
        }

        return [
            'status' => $status,
            'headers' => $httpHeaders,
            'sessionId' => $sessionId,
            'json' => $json,
        ];
    }

    private static function extractHeader(string $headers, string $name): ?string
    {
        foreach (preg_split('/\r?\n/', $headers) ?: [] as $line) {
            if (stripos($line, $name . ':') === 0) {
                return trim(substr($line, strlen($name) + 1));
            }
        }

        return null;
    }

    private static function containsPlaceholder(string $value): bool
    {
        return preg_match('/__[A-Z0-9_]+__/', $value) === 1;
    }

    /**
     * @return array<string, mixed>
     */
    private static function decodeJsonOrSse(string $raw): array
    {
        $trimmed = trim($raw);
        if ($trimmed === '') {
            return [];
        }

        $decoded = json_decode($trimmed, true);
        if (is_array($decoded)) {
            return $decoded;
        }

        $dataLines = [];
        foreach (preg_split('/\r?\n/', $trimmed) ?: [] as $line) {
            if (strpos($line, 'data:') === 0) {
                $dataLines[] = trim(substr($line, 5));
            }
        }

        if ($dataLines !== []) {
            $decoded = json_decode(implode("\n", $dataLines), true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }

        throw new RuntimeException(sprintf('Unable to decode MCP response as JSON or SSE JSON: %s', $raw));
    }
}
