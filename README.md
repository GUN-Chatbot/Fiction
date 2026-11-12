# fiction

A new Flutter project.

## Supabase setup

Apply `supabase/migrations/20261112000000_novel_creator_id.sql` to the Supabase
project before using the writing hub. It adds `novels.user_id`, which associates
new novels with their signed-in creator and allows that creator to add episodes
later.

Writing drafts are stored locally with `shared_preferences`; multiple drafts can
be saved and resumed independently on the same device.
