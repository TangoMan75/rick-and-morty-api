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

namespace App\Tests\Integration;

use Symfony\Bundle\FrameworkBundle\Test\KernelTestCase;

/**
 * A template integration test.
 *
 * @author "Matthias Morin" <mat@tangoman.io>
 */
class TemplateIntegrationTest extends KernelTestCase
{
    public function testYourDevelopmentEnvironmentWorksProperly(): void
    {
        $this->assertTrue(true);
    }
}
