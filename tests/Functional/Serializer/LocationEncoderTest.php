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

namespace App\Tests\Functional\Serializer;

use App\Serializer\LocationEncoder;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class LocationEncoderTest extends KernelTestCase
{
    private LocationEncoder $encoder;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->encoder = self::getContainer()->get(LocationEncoder::class);
    }

    public function testEncode(): void
    {
        $data = ['id' => 1, 'name' => 'Earth'];
        $encoded = $this->encoder->encode($data, LocationEncoder::FORMAT);

        $this->assertIsString($encoded);
        $this->assertEquals('{"id":1,"name":"Earth"}', $encoded);
    }

    public function testSupportsEncoding(): void
    {
        $this->assertTrue($this->encoder->supportsEncoding('json'));
        $this->assertFalse($this->encoder->supportsEncoding('xml'));
    }

    public function testDecode(): void
    {
        $json = '{"id":1,"name":"Earth"}';
        $decoded = $this->encoder->decode($json, LocationEncoder::FORMAT);

        $this->assertIsArray($decoded);
        $this->assertEquals(['id' => 1, 'name' => 'Earth'], $decoded);
    }

    public function testSupportsDecoding(): void
    {
        $this->assertTrue($this->encoder->supportsDecoding('json'));
        $this->assertFalse($this->encoder->supportsDecoding('xml'));
    }
}
