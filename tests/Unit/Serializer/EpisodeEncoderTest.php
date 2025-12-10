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

namespace App\Tests\Unit\Serializer;

use App\Serializer\EpisodeEncoder;
use PHPUnit\Framework\TestCase;

class EpisodeEncoderTest extends TestCase
{
    private EpisodeEncoder $encoder;

    protected function setUp(): void
    {
        $this->encoder = new EpisodeEncoder();
    }

    public function testEncode(): void
    {
        $data = ['name' => 'Pilot', 'episode' => 'S01E01'];
        $expected = json_encode($data);

        $result = $this->encoder->encode($data, 'json');

        $this->assertEquals($expected, $result);
    }

    public function testSupportsEncoding(): void
    {
        $this->assertTrue($this->encoder->supportsEncoding('json'));
        $this->assertFalse($this->encoder->supportsEncoding('xml'));
    }

    public function testDecode(): void
    {
        $json = '{"name":"Pilot","episode":"S01E01"}';
        $expected = json_decode($json, true);

        $result = $this->encoder->decode($json, 'json');

        $this->assertEquals($expected, $result);
    }

    public function testSupportsDecoding(): void
    {
        $this->assertTrue($this->encoder->supportsDecoding('json'));
        $this->assertFalse($this->encoder->supportsDecoding('xml'));
    }
}
