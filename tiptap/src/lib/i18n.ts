export const translate = (map: any, key: string) => {
  const source = map[document.documentElement.lang] || map.en;
  return source[key] || key;
};

export default translate;
