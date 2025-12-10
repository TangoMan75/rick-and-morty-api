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

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Generator\UrlGeneratorInterface;

class ApiController extends AbstractController
{
    #[Route('/', name: 'root', methods: ['GET'])]
    public function root(): RedirectResponse
    {
        return $this->redirect('/api/docs');
    }

    #[Route('/api', name: 'api_root', methods: ['GET'])]
    #[Route('/api/', name: 'api_root_slash', methods: ['GET'])]
    public function index(UrlGeneratorInterface $urlGenerator): JsonResponse
    {
        return new JsonResponse([
            'characters' => $urlGenerator->generate('_api_/characters{._format}_get_collection', [], UrlGeneratorInterface::ABSOLUTE_URL),
            'locations'  => $urlGenerator->generate('_api_/locations{._format}_get_collection', [], UrlGeneratorInterface::ABSOLUTE_URL),
            'episodes'   => $urlGenerator->generate('_api_/episodes{._format}_get_collection', [], UrlGeneratorInterface::ABSOLUTE_URL),
        ]);
    }
}
