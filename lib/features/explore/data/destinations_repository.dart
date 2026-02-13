import '../models/destination_model.dart';

class DestinationsRepository {
  static final List<Destination> destinations = [

    Destination(
      id: 'cartagena',
      title: 'Cartagena de Indias',
      country: 'Colombia',
      city: 'Cartagena',
      description:
          'Ciudad histórica del Caribe colombiano famosa por su ciudad amurallada, arquitectura colonial y playas tropicales.',
      mainImage:
          'https://images.unsplash.com/photo-1587595431973-160d0d94add1',
      gallery: [
        'https://images.unsplash.com/photo-1605727216801-e27ce1d0cc28',
        'https://images.unsplash.com/photo-1590080877777-9c3c4b1d651d',
        'https://images.unsplash.com/photo-1580327332925-a10e6cb11baa',
      ],
      rating: 4.7,
      reviews: 1243,
      latitude: 10.3910,
      longitude: -75.4794,
    ),

    Destination(
      id: 'kyoto',
      title: 'Kyoto',
      country: 'Japón',
      city: 'Kyoto',
      description:
          'Capital cultural de Japón, conocida por sus templos antiguos, jardines zen y tradiciones milenarias.',
      mainImage:
          'https://images.unsplash.com/photo-1545569341-9eb8b30979d9',
      gallery: [
        'https://images.unsplash.com/photo-1505066820005-9f8d1a9e5a3d',
        'https://images.unsplash.com/photo-1526481280691-3f86b6c9a3b1',
        'https://images.unsplash.com/photo-1492571350019-22de08371fd3',
      ],
      rating: 4.9,
      reviews: 2310,
      latitude: 35.0116,
      longitude: 135.7681,
    ),

  ];
}