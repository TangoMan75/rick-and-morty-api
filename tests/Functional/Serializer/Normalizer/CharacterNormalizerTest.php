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

namespace App\Tests\Functional\Serializer\Normalizer;

use App\Entity\Character;
use App\Serializer\Normalizer\CharacterNormalizer;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class CharacterNormalizerTest extends KernelTestCase
{
    private CharacterNormalizer $normalizer;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->normalizer = self::getContainer()->get(CharacterNormalizer::class);
    }

    public function testSupportsNormalization(): void
    {
        $character = new Character();
        $this->assertTrue($this->normalizer->supportsNormalization($character));
        $this->assertFalse($this->normalizer->supportsNormalization(new \stdClass()));
    }

    public function testSupportsDenormalization(): void
    {
        $this->assertTrue($this->normalizer->supportsDenormalization([], Character::class));
        $this->assertFalse($this->normalizer->supportsDenormalization([], \stdClass::class));
        $this->assertFalse($this->normalizer->supportsDenormalization('string', Character::class));
    }

    public function testGetSupportedTypes(): void
    {
        $types = $this->normalizer->getSupportedTypes(null);
        $this->assertArrayHasKey(Character::class, $types);
        $this->assertTrue($types[Character::class]);
    }
}
