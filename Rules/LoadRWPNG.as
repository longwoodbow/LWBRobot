// RW PNG loader base class - extend this to add your own PNG loading functionality!

#include "BasePNGLoader.as";
#include "MinimapHook.as";

// RW custom map colors
namespace rw_colors
{
	enum color
	{
		boss_orb = 0xFFFF0001,
		boss_ufo = 0xFFFF0002,
		base_shield = 0xFFF0F0F0
	};
}

//the loader

class RWPNGLoader : PNGLoader
{
	RWPNGLoader()
	{
		super();
	}

	//override this to extend functionality per-pixel.
	void handlePixel(const SColor &in pixel, int offset) override
	{
		PNGLoader::handlePixel(pixel, offset);

		switch (pixel.color)
		{
			case rw_colors::boss_orb: autotile(offset); spawnBlob(map, "boss_orb", offset, 1); break;
			case rw_colors::boss_ufo: autotile(offset); spawnBlob(map, "boss_ufo", offset, 1); break;
			case rw_colors::base_shield: autotile(offset); spawnBlob(map, "robot_spawn_shield", offset, -1); break;
		};
	}
};

// --------------------------------------------------

bool LoadMap(CMap@ map, const string& in fileName)
{
	print("LOADING RW PNG MAP " + fileName);

	RWPNGLoader loader();

	MiniMap::Initialise();

	return loader.loadMap(map , fileName);
}
