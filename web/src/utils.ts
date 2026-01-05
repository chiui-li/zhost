export const cls = (...classes: any[]) => {
  return classes.filter(Boolean).join(" ");
};

export const debounce = (func: Function, delay: number) => {
  let timeoutId: any = null;
  return (...args: any[]) => {
    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(() => func(...args), delay);
  };
};
