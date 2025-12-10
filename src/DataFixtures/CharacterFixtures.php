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

namespace App\DataFixtures;

use App\Entity\Character;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Faker\Factory;

class CharacterFixtures extends Fixture implements \Doctrine\Common\DataFixtures\OrderedFixtureInterface
{
    public function load(ObjectManager $manager): void
    {
        $faker = Factory::create();

        for ($i = 1; $i <= 25; ++$i) {
            $character = new Character();
            $character->setId($faker->unique()->randomNumber());
            $character->setName($faker->unique()->userName());
            $character->setStatus($faker->randomElement(['Alive', 'Dead', 'unknown']));
            $character->setSpecies($faker->randomElement(['Human', 'Alien', 'Robot', 'Disease', 'Mythological Creature']));
            $character->setType($faker->word());
            $character->setGender($faker->randomElement(['Male', 'Female', 'Genderless', 'unknown']));
            $character->setOrigin($this->getReference('origin_'.$i, \App\Entity\Location::class));
            $character->setLocation($this->getReference('location_'.$i, \App\Entity\Location::class));
            $character->setImage($faker->imageUrl(300, 300));
            $character->setUrl($faker->url());
            $character->setCreated($faker->dateTimeThisYear());

            $episode = $this->getReference('episode_'.$i, \App\Entity\Episode::class);
            $character->addEpisode($episode);
            $manager->persist($character);

            $location = $this->getReference('location_'.$i, \App\Entity\Location::class);
            $location->addResident($character);
            $manager->persist($location);

            $episode = $this->getReference('episode_'.$i, \App\Entity\Episode::class);
            $episode->addCharacter($character);
            $manager->persist($episode);
        }

        $manager->flush();
    }

    public function getOrder(): int
    {
        return 3;
    }
}
