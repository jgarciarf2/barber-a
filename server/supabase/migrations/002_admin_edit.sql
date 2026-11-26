-- Añade edición de reservas existentes desde el panel privado.
grant select, insert, update, delete on table public.bookings to service_role;
