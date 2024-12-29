# M'Trotter

Configuration de gradle.properties
Pour optimiser les performances et garantir la compatibilité avec AndroidX, vous devez ajouter manuellement un fichier gradle.properties dans le répertoire /android avec les valeurs suivantes :

Contenu du fichier gradle.properties

org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G -XX:+HeapDumpOnOutOfMemoryError
org.gradle.java.home=CHEMIN_VERS_JAVA
android.useAndroidX=true
android.enableJetifier=true
Spécificités selon le système d'exploitation
Sous Windows : Modifiez org.gradle.java.home pour pointer vers le chemin de votre installation JDK. Exemple :


org.gradle.java.home=C:/Program Files/Java/jdk-17
Sous Linux : Modifiez org.gradle.java.home pour pointer vers le chemin de votre installation JDK. Exemple :

properties
Copier le code
org.gradle.java.home=/usr/lib/jvm/java-17-openjdk