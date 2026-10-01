import { requireSupabase } from '../lib/supabase';

export async function fetchProducts({ search = '', category = '', sort = 'featured', min = '', max = '', available = false, featured = false, limit = 48 } = {}) {
  const db = requireSupabase();
  let query = db.from('products').select('*, categories(name), product_images(image_url,alt_text,sort_order)').eq('active', true).limit(limit);
  if (search.trim()) query = query.ilike('name', `%${search.trim().replace(/[%_]/g, '')}%`);
  if (category) query = query.eq('category_id', category);
  if (min !== '') query = query.gte('price', Number(min));
  if (max !== '') query = query.lte('price', Number(max));
  if (available) query = query.gt('stock_quantity', 0);
  if (featured) query = query.eq('featured', true);
  if (sort === 'price-asc') query = query.order('price', { ascending: true });
  else if (sort === 'price-desc') query = query.order('price', { ascending: false });
  else query = query.order('created_at', { ascending: false });
  const { data, error } = await query;
  if (error) throw error;
  return sort === 'featured' ? [...(data || [])].sort((a, b) => Number(b.featured) - Number(a.featured)) : (data || []);
}
export async function fetchCategories() { const { data, error } = await requireSupabase().from('categories').select('*').eq('active', true).order('name'); if (error) throw error; return data || []; }
export async function fetchGallery() { const { data, error } = await requireSupabase().from('gallery').select('*').eq('active', true).order('sort_order').order('created_at', { ascending: false }); if (error) throw error; return data || []; }
export async function fetchProduct(id) { const { data, error } = await requireSupabase().from('products').select('*, categories(name), product_images(image_url,alt_text,sort_order)').eq('id', id).eq('active', true).single(); if (error) throw error; return data; }
