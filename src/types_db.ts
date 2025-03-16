export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          created_at: string;
          privy_id: string | null;
          username: string | null;
          bio: string | null;
          avatar_url: string | null;
          twitter: string | null;
          instagram: string | null;
          linkedin: string | null;
          website: string | null;
          updated_at: string | null;
          primary_color: string | null;
          secondary_color: string | null;
          body_color: string | null;
          card_color: string | null;
        };
        Insert: {
          id?: string;
          created_at?: string;
          privy_id?: string | null;
          username?: string | null;
          bio?: string | null;
          avatar_url?: string | null;
          twitter?: string | null;
          instagram?: string | null;
          linkedin?: string | null;
          website?: string | null;
          updated_at?: string | null;
          primary_color?: string | null;
          secondary_color?: string | null;
          body_color?: string | null;
          card_color?: string | null;
        };
        Update: {
          id?: string;
          created_at?: string;
          privy_id?: string | null;
          username?: string | null;
          bio?: string | null;
          avatar_url?: string | null;
          twitter?: string | null;
          instagram?: string | null;
          linkedin?: string | null;
          website?: string | null;
          updated_at?: string | null;
          primary_color?: string | null;
          secondary_color?: string | null;
          body_color?: string | null;
          card_color?: string | null;
        };
      };
      referrals: {
        Row: {
          id: string;
          created_at: string;
          user_id: string;
          title: string;
          description: string | null;
          url: string;
          image_url: string | null;
          subtitle: string | null;
          tags: string | null;
        };
        Insert: {
          id?: string;
          created_at?: string;
          user_id: string;
          title: string;
          description?: string | null;
          url: string;
          image_url?: string | null;
          subtitle?: string | null;
          tags?: string | null;
        };
        Update: {
          id?: string;
          created_at?: string;
          user_id?: string;
          title?: string;
          description?: string | null;
          url?: string;
          image_url?: string | null;
          subtitle?: string | null;
          tags?: string | null;
        };
      };
      tags: {
        Row: {
          id: string;
          created_at: string;
          user_id: string;
          name: string;
        };
        Insert: {
          id?: string;
          created_at?: string;
          user_id: string;
          name: string;
        };
        Update: {
          id?: string;
          created_at?: string;
          user_id?: string;
          name?: string;
        };
      };
      referral_tags: {
        Row: {
          referral_id: string;
          tag_id: string;
        };
        Insert: {
          referral_id: string;
          tag_id: string;
        };
        Update: {
          referral_id?: string;
          tag_id?: string;
        };
      };
    };
    Views: {
      [_ in never]: never;
    };
    Functions: {
      [_ in never]: never;
    };
    Enums: {
      [_ in never]: never;
    };
  };
}