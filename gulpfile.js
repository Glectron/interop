import gulp from 'gulp';
import fs from 'fs/promises';
import { glob } from 'glob';
import esbuild from 'esbuild';

async function buildLua() {
    try {
        // Read all handler files
        const handlerFiles = glob.sync('src/lua/handlers/*.lua');
        
        // Read and concatenate handler contents
        let handlerContents = '';
        for (const file of handlerFiles) {
            const content = await fs.readFile(file, 'utf8');
            handlerContents += content + '\n';
        }
        
        // Read the main interop file
        const interopContent = await fs.readFile('src/lua/interop.lua', 'utf8');
        
        // Replace the placeholder with handler contents
        const result = interopContent.replace('-- @HANDLER --', handlerContents.trim());
        
        // Ensure output directory exists
        await fs.mkdir('build', { recursive: true });
        
        // Write the result
        await fs.writeFile('build/interop.lua', result);
        
        console.log('✓ Built interop.lua with handlers');
    } catch (error) {
        console.error('Build failed:', error);
        throw error;
    }
}

async function buildTypeScript() {
    try {
        await esbuild.build({
            entryPoints: ['src/js/interop.ts'],
            bundle: true,
            outfile: 'build/interop.js',
            platform: 'browser',
            target: 'es2021',
            format: 'cjs',
            sourcemap: true,
            minify: false
        });
        
        console.log('✓ Built interop.js from TypeScript');
    } catch (error) {
        console.error('TypeScript build failed:', error);
        throw error;
    }
}

gulp.task('build:lua', buildLua);
gulp.task('build:ts', buildTypeScript);
gulp.task('build', gulp.parallel('build:lua', 'build:ts'));
gulp.task('default', gulp.series('build'));

// Watch task for development
gulp.task('watch', () => {
    gulp.watch(['src/lua/interop.lua', 'src/lua/handlers/*.lua'], gulp.series('build:lua'));
    gulp.watch(['src/js/**/*.ts'], gulp.series('build:ts'));
});
