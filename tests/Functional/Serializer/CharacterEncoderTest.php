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

use App\Serializer\CharacterEncoder;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class CharacterEncoderTest extends KernelTestCase
{
    private CharacterEncoder $encoder;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->encoder = self::getContainer()->get(CharacterEncoder::class);
    }

    public function testEncode(): void
    {
        $data = ['id' => 1, 'name' => 'Rick Sanchez'];
        $encoded = $this->encoder->encode($data, CharacterEncoder::FORMAT);

        $this->assertIsString($encoded);
        $this->assertEquals('{"id":1,"name":"Rick Sanchez"}', $encoded);
    }

    public function testSupportsEncoding(): void
    {
        $this->assertTrue($this->encoder->supportsEncoding('json'));
        $this->assertFalse($this->encoder->supportsEncoding('xml'));
    }

    public function testDecode(): void
    {
        $json = '{"id":1,"name":"Rick Sanchez"}';
        $decoded = $this->encoder->decode($json, CharacterEncoder::FORMAT);

        $this->assertIsArray($decoded);
        $this->assertEquals(['id' => 1, 'name' => 'Rick Sanchez'], $decoded);
    }

    public function testSupportsDecoding(): void
    {
        $this->assertTrue($this->encoder->supportsDecoding('json'));
        $this->assertFalse($this->encoder->supportsDecoding('xml'));
    }
}
