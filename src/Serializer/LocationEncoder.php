<?php

declare(strict_types=1);

/*
 * This file is part of the TangoMan package.
 *
 * (c) "Matthias Morin" <mat@tangoman.io>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

namespace App\Serializer;

use Symfony\Component\Serializer\Encoder\DecoderInterface;
use Symfony\Component\Serializer\Encoder\EncoderInterface;

class LocationEncoder implements EncoderInterface, DecoderInterface
{
    public const FORMAT = 'json';

    public function encode(mixed $data, string $format, array $context = []): string
    {
        return json_encode($data);
    }

    public function supportsEncoding(string $format): bool
    {
        return self::FORMAT === $format;
    }

    public function decode(string $data, string $format, array $context = []): mixed
    {
        return json_decode($data, true);
    }

    public function supportsDecoding(string $format): bool
    {
        return self::FORMAT === $format;
    }
}
