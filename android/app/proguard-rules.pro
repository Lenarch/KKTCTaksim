# Release derlemesinde R8'in silmemesi gereken sınıflar.

# WorkManager (reklam ve Google Play hizmetleri kullanıyor) veritabanını Room ile, oluşturulan
# `WorkDatabase_Impl` sınıfını yansımayla (reflection) bularak açar. R8 bu sınıfı silince uygulama
# açılır açılmaz "Failed to create an instance of androidx.work.impl.WorkDatabase" ile çöküyordu.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
