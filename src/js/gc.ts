export const finalizationRegistry = new FinalizationRegistry((id: string) => {
    _interop_lua_.collect(id);
});