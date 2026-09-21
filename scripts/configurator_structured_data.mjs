export const configuratorSchemaId = 'cfmoto-configurator-structured-data';

export const configuratorStructuredData = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'WebPage',
      '@id': 'https://cfmoto.az/aksesuar-konfiquratoru/#webpage',
      url: 'https://cfmoto.az/aksesuar-konfiquratoru/',
      name: 'CFMOTO Aksesuar Konfiquratoru: Moto, ATV və Buggy',
      description: 'CFMOTO motosiklet, ATV və Buggy modelləri üçün orijinal aksesuarları seçin, yerli AZN qiymətləri ilə paket hazırlayın və satış komandası ilə paylaşın.',
      inLanguage: 'az',
      breadcrumb: { '@id': 'https://cfmoto.az/aksesuar-konfiquratoru/#breadcrumb' },
    },
    {
      '@type': 'BreadcrumbList',
      '@id': 'https://cfmoto.az/aksesuar-konfiquratoru/#breadcrumb',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Ana səhifə', item: 'https://cfmoto.az/' },
        { '@type': 'ListItem', position: 2, name: 'Aksesuar konfiquratoru', item: 'https://cfmoto.az/aksesuar-konfiquratoru/' },
      ],
    },
  ],
};
