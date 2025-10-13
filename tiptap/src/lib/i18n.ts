export const translate = (map: Record<string, Record<string, string>>, key: string) => {
  const source = map[document.documentElement.lang] || map.en;
  return source[key] || key;
};

export default translate;
