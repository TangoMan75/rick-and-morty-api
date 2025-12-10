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

use App\Entity\Location;
use App\Serializer\Normalizer\LocationNormalizer;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class LocationNormalizerTest extends KernelTestCase
{
    private LocationNormalizer $normalizer;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->normalizer = self::getContainer()->get(LocationNormalizer::class);
    }

    public function testSupportsNormalization(): void
    {
        $location = new Location();
        $this->assertTrue($this->normalizer->supportsNormalization($location));
        $this->assertFalse($this->normalizer->supportsNormalization(new \stdClass()));
    }

    public function testSupportsDenormalization(): void
    {
        $this->assertTrue($this->normalizer->supportsDenormalization([], Location::class));
        $this->assertFalse($this->normalizer->supportsDenormalization([], \stdClass::class));
        $this->assertFalse($this->normalizer->supportsDenormalization('string', Location::class));
    }

    public function testGetSupportedTypes(): void
    {
        $types = $this->normalizer->getSupportedTypes(null);
        $this->assertArrayHasKey(Location::class, $types);
        $this->assertTrue($types[Location::class]);
    }
}
