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

use App\Entity\Episode;
use App\Serializer\Normalizer\EpisodeNormalizer;
use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

class EpisodeNormalizerTest extends KernelTestCase
{
    private EpisodeNormalizer $normalizer;

    protected function setUp(): void
    {
        self::bootKernel();
        $this->normalizer = self::getContainer()->get(EpisodeNormalizer::class);
    }

    public function testSupportsNormalization(): void
    {
        $episode = new Episode();
        $this->assertTrue($this->normalizer->supportsNormalization($episode));
        $this->assertFalse($this->normalizer->supportsNormalization(new \stdClass()));
    }

    public function testSupportsDenormalization(): void
    {
        $this->assertTrue($this->normalizer->supportsDenormalization([], Episode::class));
        $this->assertFalse($this->normalizer->supportsDenormalization([], \stdClass::class));
        $this->assertFalse($this->normalizer->supportsDenormalization('string', Episode::class));
    }

    public function testGetSupportedTypes(): void
    {
        $types = $this->normalizer->getSupportedTypes(null);
        $this->assertArrayHasKey(Episode::class, $types);
        $this->assertTrue($types[Episode::class]);
    }
}
