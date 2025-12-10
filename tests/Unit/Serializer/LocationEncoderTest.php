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

use App\Serializer\LocationEncoder;
use PHPUnit\Framework\TestCase;

class LocationEncoderTest extends TestCase
{
    private LocationEncoder $encoder;

    protected function setUp(): void
    {
        $this->encoder = new LocationEncoder();
    }

    public function testEncode(): void
    {
        $data = [
            'id'   => 1,
            'name' => 'Earth (C-137)',
            'type' => 'Planet',
        ];
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
        $json = '{"name":"Earth (C-137)","type":"Planet"}';
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
